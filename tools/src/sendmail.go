package main

import (
	"fmt"
	"ioutil"
	"log"
	"net/smtp"
	"os"
)

func main() {
	if len(os.Args) == 1 {
		log.Fatal("no path provided")
	}
	data, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		log.Fatal(err)
	}

	c, err := smtp.Dial("localhost:1025")
	if err != nil {
		log.Fatal(err)
	}
	if err := c.Mail("linux@dtu.dk"); err != nil {
		log.Fatal(err)
	}
	if err := c.Rcpt("mail@mama.sh"); err != nil {
		log.Fatal(err)
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
