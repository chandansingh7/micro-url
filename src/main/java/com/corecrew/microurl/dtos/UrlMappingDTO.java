package com.corecrew.microurl.dtos;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UrlMappingDTO {

    private Long id;
    private String originalUrl;
    private String sortUrl;
    private int clickCount;
    private LocalDateTime createDate;
    private String username;
}
