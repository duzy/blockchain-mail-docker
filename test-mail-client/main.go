package main

import (
        "net/smtp"
        "flags"
        "fmt"
        "log"
)

var (
        optionPort = 8125
)

func init() {
        flag.IntVar(&optionPort, "port", "port number")
}

func main() {
        var (
                ip
        )
        
        flag.Parse()

        if n := flag.NArg(); n == 1 {
                ip = flag.Arg(0)
        } else if 1 < n {
                log.Fatalf("wrong arguments")
                return
        }
        
        c, err := smtp.Dial(fmt.Sprintf("%s:%s"), ip, optionPort)
        if err != nil {
                log.Fatal(err)
        }

        defer c.Close()
        
        if err := c.Mail("test@example.org"); err != nil {
                log.Fatal(err)
        }
        if err := c.Rcpt("recipient@example.org"); err != nil {
                log.Fatal(err)
        }
        
        w, err := c.Data()
        if err != nil {
                log.Fatal(err)
        }
        
        _, err = fmt.Fprintf(w, "This is a test message.")
        if err != nil {
                log.Fatal(err)
        }
        
        if err = w.Close(); err != nil {
                log.Fatal(err)
        }

        if err = c.Quit(); err != nil {
                log.Fatal(err)
        }
}
