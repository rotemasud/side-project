package com.example.side_project;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

	@Value("${app.version}")
	private String appVersion;

	@GetMapping("/")
	public String index() {


		//Ec2MetadataClient client = Ec2MetadataClient.create();
		//Ec2MetadataResponse response = client.get("/latest/meta-data/placement/availability-zone-id");
		//System.out.println(response.asString());
		//client.close(); // Closes the internal resources used by the Ec2MetadataClient class.

		return "Greetings from Spring Boot! - Version " + appVersion;
	}

}