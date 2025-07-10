package com.benrhine.kubernetes_example_simple.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

//https://www.geeksforgeeks.org/how-to-make-a-simple-restcontroller-in-spring-boot/

@RestController
@RequestMapping("/api")
public class Controller {

    @GetMapping("/hello/{name}/{age}")
    public String sayHello(@PathVariable String name, @PathVariable int age) {
        return "Hello, " + name + "! You are " + age + " years old.";
    }
}
