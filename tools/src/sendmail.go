package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/smtp"
	"os"
	"strconv"
)

type config struct {
	smtpserver host
	from       string
	to         []string
}

type host struct {
	ip   string
	port int
}

func (h *host) String() string {
	return h.ip + ":" + strconv.Itoa(h.port)
}

func main() {
	conf, err := NewConf()
	if err != nil {
		log.Fatalf("Loading mail config file failed: %v", err)
	}
	if len(os.Args) == 1 {
		log.Fatal("no path provided")
	}
	data, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		log.Fatal(err)
	}

	c, err := smtp.Dial(conf.smtpserver.String())
	if err != nil {
		log.Fatal(err)
	}
	if err := c.Mail(conf.from); err != nil {
		log.Fatal(err)
	}
	for _, rcpt := range conf.to {
		if err := c.Rcpt(rcpt); err != nil {
			log.Fatal(err)
		}
	}
	wc, err := c.Data()
	if err != nil {
		log.Fatal(err)
	}
	_, err = fmt.Fprintf(wc, string(data))
	if err != nil {
		log.Fatal(err)
	}
	err = wc.Close()
	if err != nil {
		log.Fatal(err)
	}
	err = c.Quit()
	if err != nil {
		log.Fatal(err)
	}
}

func NewConf() (c config, err error) {
	confPath := os.Getenv("MAIL_CONF")
	if confPath == "" {
		return c, errors.New("no config file provided")
	}
	data, err := ioutil.ReadFile(confPath)
	err = json.Unmarshal(data, &c)
	return
}
