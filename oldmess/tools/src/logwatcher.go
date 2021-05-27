package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

type config struct {
	Out     string
	Process []string
}

type logmessage struct {
	Service string
	Time    string
	Content string
}

func main() {
	config, err := NewProcessConf()
	if err != nil {
		log.Fatal(err)
	}
	msg := make(chan logmessage)
	for _, e := range config.Process {
		cmd := exec.Command("journalctl", "-u", e, "-ojson", "--follow")
		follow, err := runCommand(cmd)
		if err != nil {
			log.Fatal(err)
		}
		go follow(e, msg)
	}
	for {
		logmsg := <-msg
		config.writeLine(logmsg)
	}
}

func getNiceTimeFormat(in string) string {
	unix, err := strconv.Atoi(in)
	if err != nil {
		return ""
	}
	return time.Unix(0, int64(unix)*1000).Format("2006-01-02 15:04:05")
}

func (c *config) writeLine(l logmessage) error {
	f, err := os.OpenFile(c.Out, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = f.WriteString("--------------------------------\n")
	_, err = f.WriteString(strings.ToUpper(l.Service) + "\n")
	_, err = f.WriteString("\t" + l.Time + "\n")
	_, err = f.WriteString("\t" + l.Content + "\n")
	_, err = f.WriteString("\n")
	return err
}

func followJournal(stdout io.ReadCloser, service string, c chan<- logmessage) {
	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		var e map[string]string
		json.Unmarshal(scanner.Bytes(), &e)
		c <- logmessage{
			Service: service,
			Time:    getNiceTimeFormat(e["__REALTIME_TIMESTAMP"]),
			Content: e["MESSAGE"],
		}
	}
}

func runCommand(c *exec.Cmd) (f func(service string, out chan<- logmessage), err error) {
	stdout, err := c.StdoutPipe()
	if err != nil {
		return
	}
	err = c.Start()
	if err != nil {
		return
	}
	f = func(service string, out chan<- logmessage) {
		followJournal(stdout, service, out)
		err = c.Wait()
		if err != nil {
			log.Fatal(err)
		}
		log.Println("Finished", service)
	}
	return
}

func NewProcessConf() (c config, err error) {
	if len(os.Args) == 1 {
		return c, errors.New("no config file provided")
	}
	config, err := ioutil.ReadFile(os.Args[1])
	err = json.Unmarshal(config, &c)
	return
}
