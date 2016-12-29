package main

import (
        "net/smtp"
        "flag"
        "fmt"
        "log"
)

var (
        optionPort int
)

func init() {
        flag.IntVar(&optionPort, "port", 8125, "port number")
}

func main() {
        var (
                ip string
                addr string
        )
        
        flag.Parse()

        if n := flag.NArg(); n == 1 {
                ip = flag.Arg(0)
        } else if 1 < n {
                log.Fatalf("wrong arguments")
                return
        } else {
                ip = "172.17.0.4"
        }

        addr = fmt.Sprintf("%s:%d", ip, optionPort)
        log.Printf("Dial %v", addr)
        
        c, err := smtp.Dial(addr)
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
