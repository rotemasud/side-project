package com.example.side_project;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

	@GetMapping("/")
	public String index() {


		//Ec2MetadataClient client = Ec2MetadataClient.create();
		//Ec2MetadataResponse response = client.get("/latest/meta-data/placement/availability-zone-id");
		//System.out.println(response.asString());
		//client.close(); // Closes the internal resources used by the Ec2MetadataClient class.

		return "Greetings from Spring Boot!";
	}

}