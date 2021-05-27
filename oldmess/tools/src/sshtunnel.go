package main

import (
	"encoding/json"
	"errors"
	"golang.org/x/crypto/ssh"
	"io"
	"io/ioutil"
	"log"
	"net"
	"os"
	"strconv"
)

type attributes struct {
	Username string
	KeyFile  string
	Server   host
	Local    host
	Remote   host
}

type host struct {
	Host string
	Port int
}

func (h *host) String() string {
	return h.Host + ":" + strconv.Itoa(h.Port)
}

func NewConf() (a attributes, err error) {
	if len(os.Args) == 1 {
		return a, errors.New("no config file provided")
	}
	config, err := ioutil.ReadFile(os.Args[1])
	err = json.Unmarshal(config, &a)
	return
}

func forward(localConn net.Conn, config *ssh.ClientConfig, a attributes) {
	// Setup sshClientConn (type *ssh.ClientConn)
	sshClientConn, err := ssh.Dial("tcp", a.Server.String(), config)
	if err != nil {
		log.Fatalf("ssh.Dial failed: %s", err)
	}

	// Setup sshConn (type net.Conn)
	sshConn, err := sshClientConn.Dial("tcp", a.Remote.String())

	// Copy localConn.Reader to sshConn.Writer
	go func() {
		_, err = io.Copy(sshConn, localConn)
		if err != nil && err != io.EOF {
			log.Fatalf("io.Copy failed: %v", err)
		}
	}()

	// Copy sshConn.Reader to localConn.Writer
	go func() {
		_, err = io.Copy(localConn, sshConn)
		if err != nil {
			log.Fatalf("io.Copy failed: %v", err)
		}
	}()
}

func getKey(path string) (key []byte, err error) {
	return ioutil.ReadFile(path)
}

func main() {
	attrs, err := NewConf()
	if err != nil {
		log.Fatal(err)
	}

	var hostKey ssh.PublicKey

	key, err := getKey(attrs.KeyFile)
	if err != nil {
		log.Fatal(err)
	}

	signer, err := ssh.ParsePrivateKey(key)
	if err != nil {
		log.Fatal(err)
	}

	config := &ssh.ClientConfig{
		User: attrs.Username,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
		HostKeyCallback: ssh.FixedHostKey(hostKey),
	}

	// Setup localListener (type net.Listener)
	localListener, err := net.Listen("tcp", attrs.Local.String())
	if err != nil {
		log.Fatalf("net.Listen failed: %v", err)
	}

	for {
		// Setup localConn (type net.Conn)
		localConn, err := localListener.Accept()
		if err != nil {
			log.Fatalf("listen.Accept failed: %v", err)
		}
		go forward(localConn, config, attrs)
	}
}
