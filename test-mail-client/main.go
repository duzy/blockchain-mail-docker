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

        // 1KvwTxFqJSSjztyEN3LLmLDWr4xVZtGk96@example.org
        if err := c.Mail("1C6AbpVYSU9k6Z1jZEviuqLfS4E1XHNmwa"); err != nil {
                log.Fatal(err)
        }
        // "1PkyncFDsXmcg6pnPUvNJWougztWejAdVe@example.org"
        if err := c.Rcpt("1QH4nxaBd6GTEetos3NmMVUDFS4ukc5xNK"); err != nil {
                log.Fatal(err)
        }
        
        w, err := c.Data()
        if err != nil {
                log.Fatal(err)
        }
        
        _, err = fmt.Fprintf(w, "test message, line  1..\r\n.\r\n..\r\n...\r\n")
        if err != nil {
                log.Fatal(err)
        }
        _, err = fmt.Fprintf(w, "test message, line 2..\r\n.\r\n..\r\n...\r\n")
        if err != nil {
                log.Fatal(err)
        }
        _, err = fmt.Fprintf(w, "test message, line 3..\r\n.\r\n..\r\n...\r\n")
        if err != nil {
                log.Fatal(err)
        }
        _, err = fmt.Fprintf(w, ".test message, line 4..\n.aaa\n.bbb\n.ccc");
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
