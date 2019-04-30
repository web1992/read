# spring-boot-starter

## POM

```xml
<!-- use Parent pom -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.1.4.RELEASE</version>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>

<!-- use dependencyManagement -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <!-- Import dependency management from Spring Boot -->
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>2.1.4.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

## maven

Maven users can inherit from the `spring-boot-starter-parent` project to obtain sensible defaults.

The parent project provides the following features:

- Java 1.8 as the default compiler level.
- UTF-8 source encoding.
- A Dependency Management section, inherited from the spring-boot-dependencies pom, that manages the versions of common dependencies. This dependency management lets you omit `<version>` tags for those dependencies when used in your own pom.
- An execution of the repackage goal with a repackage execution id.
- Sensible resource filtering.
- Sensible plugin configuration (exec plugin, Git commit ID, and shade).
- Sensible resource filtering for `application.properties` and `application.yml `including profile-specific files (for example, `application-dev.properties` and `application-dev.yml`)

Note that, since the application.properties and application.yml files accept Spring style placeholders (${…​}), the Maven filtering is changed to use @..@ placeholders. (You can override that by setting a Maven property called resource.delimiter.)

## Use maven run spring boot

```sh
mvn spring-boot:run
```

## Executable jar

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

## Starters

[https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#using-boot-starter](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#using-boot-starter)