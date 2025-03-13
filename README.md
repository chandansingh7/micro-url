# Micro-URL

Micro-URL is a simple and efficient URL shortening service built with **Spring Boot** and **MySQL**. It allows users to shorten long URLs into compact links and retrieve original URLs via generated short links.

## Features
- Shorten long URLs into compact links
- Retrieve original URLs using short links
- Secure API with CORS configuration
- Uses MySQL as the database
- Built with **Spring Boot** for scalability and efficiency

## Tech Stack
- **Backend**: Java, Spring Boot, Spring MVC, Spring Data JPA
- **Database**: MySQL
- **Security**: CORS configuration
- **Build Tool**: Gradle

## Prerequisites
Ensure you have the following installed:
- Java 17+
- MySQL Server
- Gradle

## Setup and Installation

### 1. Clone the Repository
```sh
git clone https://github.com/chandansingh7/micro-url.git
cd micro-url
```

### 2. Configure Database
Create a MySQL database:
```sql
CREATE DATABASE micro_url_db;
```

Update `src/main/resources/application.properties` with your database credentials:
```properties
spring.datasource.url=jdbc:mysql://localhost:3306/micro_url_db
spring.datasource.username=root
spring.datasource.password=yourpassword
spring.jpa.hibernate.ddl-auto=update
spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect
```

### 3. Build and Run the Application
#### Using Gradle:
```sh
./gradlew clean build
./gradlew bootRun
```

#### Using Java:
```sh
java -jar build/libs/micro-url-0.0.1-SNAPSHOT.jar
```

The application will start on **`http://localhost:8080`**.

## API Endpoints
### 1. Shorten a URL
**POST** `/api/shorten`
#### Request Body:
```json
{
  "longUrl": "https://www.example.com/very-long-url"
}
```
#### Response:
```json
{
  "shortUrl": "http://localhost:8080/u/abcd1234"
}
```

### 2. Retrieve Original URL
**GET** `/u/{shortCode}`
- Redirects to the original URL.

## CORS Configuration
CORS settings are managed in `WebConfig.java`. To modify allowed origins, update `frontend.url` in `application.properties`:
```properties
frontend.url=http://localhost:3000
```

## Contributing
1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -m "Add new feature"`
4. Push to the branch: `git push origin feature-name`
5. Open a Pull Request

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact
For queries or contributions, reach out to **[Chandan Singh](https://github.com/chandansingh7)**.

