# Unit Testing

主要内容：

- less dependent on the container
- mock objects
- test utils

目录:

- 01 [Mock Objects](#01-mock-objects)
- 02 [Unit Testing support Classes](#02-unit-testing-support-classes)

True unit tests typically run extremely quickly, as there is no runtime infrastructure to set up. Emphasizing(`强调`) true unit tests as part of your development methodology will boost your productivity. You may not need this section of the testing chapter to help you write effective unit tests for your IoC-based applications. For certain unit testing scenarios, however, the Spring Framework provides the following mock objects and testing support classes.

## 01 Mock Objects

### Environment

`org.springframework.mock.env`

- MockEnvironment
- MockPropertySource

### JNDI

`org.springframework.mock.jndi`

### Servlet API

`org.springframework.mock.web`

The `org.springframework.mock.web` package contains a comprehensive set of Servlet API mock objects that are useful for testing web contexts, controllers, and filters. These mock objects are targeted at usage with Spring’s Web MVC framework and are generally more convenient to use than dynamic mock objects such as EasyMock or alternative Servlet API mock objects such as MockObjects. Since Spring Framework 4.0, the set of mocks in the `org.springframework.mock.web` package is based on the Servlet 3.0 API.

For thorough integration testing of your Spring MVC and REST Controllers in conjunction with your WebApplicationContext configuration for Spring MVC, see the [Spring MVC Test Framework](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#spring-mvc-test-framework).

### Portlet API

The `org.springframework.mock.web.portlet` package contains a set of Portlet API mock objects, targeted at usage with Spring’s Portlet MVC framework.

## 02 Unit Testing support Classes

[link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#unit-testing-support-classes)

`org.springframework.test.util`

ReflectionTestUtils is a collection of reflection-based utility methods. Developers use these methods in testing scenarios where they need to change the value of a constant, set a non-public field, invoke a non-public setter method, or invoke a non-public configuration or lifecycle callback method when testing application code involving use cases such as the following.

`ReflectionTestUtils`

`AopTestUtils`

To unit test your Spring MVC Controllers as POJOs, use ModelAndViewAssert combined with MockHttpServletRequest, MockHttpSession, and so on from Spring’s Servlet API mocks. For thorough integration testing of your Spring MVC and REST Controllers in conjunction with your WebApplicationContext configuration for Spring MVC, use the Spring MVC Test Framework instead.

`ModelAndViewAssert`

`MockHttpServletRequest`

`MockHttpSession`
