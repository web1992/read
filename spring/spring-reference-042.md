# Extensible XML authoring

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#xml-custom)

## Introduction

Since version 2.0, Spring has featured a mechanism for schema-based extensions to the `basic Spring XML format for defining and configuring beans`. This section is devoted to detailing how you would go about writing your own custom XML bean definition parsers and integrating such parsers into the Spring IoC container.

Creating new XML configuration extensions can be done by following these (relatively) simple steps:

- Authoring an XML schema to describe your custom element(s).
- Coding a custom `NamespaceHandler` implementation (this is an easy step, don’t worry).
- Coding one or more `BeanDefinitionParser` implementations (this is where the real work is done).
- Registering the above artifacts with Spring (this too is an easy step).

## Authoring the schema

Creating an XML configuration extension for use with Spring’s IoC container starts with authoring an XML Schema to describe the extension. What follows is the schema we’ll use to configure SimpleDateFormat objects.

```xml
<myns:dateformat id="dateFormat"
    pattern="yyyy-MM-dd HH:mm"
    lenient="true"/>
```

```xsd
<!-- myns.xsd (inside package org/springframework/samples/xml) -->

<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns="http://www.mycompany.com/schema/myns"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:beans="http://www.springframework.org/schema/beans"
        targetNamespace="http://www.mycompany.com/schema/myns"
        elementFormDefault="qualified"
        attributeFormDefault="unqualified">

    <xsd:import namespace="http://www.springframework.org/schema/beans"/>

    <xsd:element name="dateformat">
        <xsd:complexType>
            <xsd:complexContent>
                <xsd:extension base="beans:identifiedType">
                    <xsd:attribute name="lenient" type="xsd:boolean"/>
                    <xsd:attribute name="pattern" type="xsd:string" use="required"/>
                </xsd:extension>
            </xsd:complexContent>
        </xsd:complexType>
    </xsd:element>
</xsd:schema>
```

## Coding a NamespaceHandler

In addition to the schema, we need a NamespaceHandler that will parse all elements of this specific namespace Spring encounters while parsing configuration files. The NamespaceHandler should in our case take care of the parsing of the myns:dateformat element.

```java
package org.springframework.samples.xml;

import org.springframework.beans.factory.xml.NamespaceHandlerSupport;

public class MyNamespaceHandler extends NamespaceHandlerSupport {

    public void init() {
        registerBeanDefinitionParser("dateformat", new SimpleDateFormatBeanDefinitionParser());
    }

}
```

## BeanDefinitionParser

```java
package org.springframework.samples.xml;

import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.xml.AbstractSingleBeanDefinitionParser;
import org.springframework.util.StringUtils;
import org.w3c.dom.Element;

import java.text.SimpleDateFormat;

public class SimpleDateFormatBeanDefinitionParser extends AbstractSingleBeanDefinitionParser { // 1

    protected Class getBeanClass(Element element) {
        return SimpleDateFormat.class; // 2
    }

    protected void doParse(Element element, BeanDefinitionBuilder bean) {   
        // this will never be null since the schema explicitly requires that a value be supplied
        String pattern = element.getAttribute("pattern");
        bean.addConstructorArg(pattern);

        // this however is an optional property
        String lenient = element.getAttribute("lenient");
        if (StringUtils.hasText(lenient)) {
            bean.addPropertyValue("lenient", Boolean.valueOf(lenient));
        }
    }

}
```

- 1 We use the Spring-provided AbstractSingleBeanDefinitionParser to handle a lot of the basic grunt work of creating a single BeanDefinition.
- 2 We supply the AbstractSingleBeanDefinitionParser superclass with the type that our single BeanDefinition will represent.

## Registering the handler and the schema

> 'META-INF/spring.handlers'

`http\://www.mycompany.com/schema/myns=org.springframework.samples.xml.MyNamespaceHandler`

> 'META-INF/spring.schemas'

`http\://www.mycompany.com/schema/myns/myns.xsd=org/springframework/samples/xml/myns.xsd`

## Using a custom extension in your Spring XML configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:myns="http://www.mycompany.com/schema/myns"
    xsi:schemaLocation="
        http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.mycompany.com/schema/myns http://www.mycompany.com/schema/myns/myns.xsd">

    <!-- as a top-level bean -->
    <myns:dateformat id="defaultDateFormat" pattern="yyyy-MM-dd HH:mm" lenient="true"/>

    <bean id="jobDetailTemplate" abstract="true">
        <property name="dateFormat">
            <!-- as an inner bean -->
            <myns:dateformat pattern="HH:mm MM-dd-yyyy"/>
        </property>
    </bean>

</beans>
```

## Nesting custom tags within custom tags

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#extensible-xml-custom-nested)

## Custom attributes on 'normal' elements

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#extensible-xml-custom-just-attributes)