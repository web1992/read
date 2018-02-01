# Marshalling XML using O/X Mappers

## Introduction

In this chapter, we will describe Spring’s Object/XML Mapping support. Object/XML Mapping, or O/X mapping for short, is the act of converting an XML document to and from an object. This conversion process is also known as XML Marshalling, or XML Serialization. This chapter uses these terms interchangeably.

Within the field of O/X mapping, a marshaller is responsible for serializing an object (graph) to XML. In similar fashion, an unmarshaller deserializes the XML to an object graph. This XML can take the form of a DOM document, an input or output stream, or a SAX handler.

Some of the benefits of using Spring for your O/X mapping needs are:

- [Ease of configuration](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#_ease_of_configuration)
- [Consistent interfaces](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#_consistent_interfaces)
- [Consistent exception hierarchy](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#_consistent_exception_hierarchy)


> spring object -> xml / xml -> object

As stated in the introduction, a marshaller serializes an object to XML, and an unmarshaller deserializes XML stream to an object. In this section, we will describe the two Spring interfaces used for this purpose.

## Marshaller

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#oxm-marshaller)

## Unmarshaller

[Link](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#oxm-unmarshaller)

## XmlMappingException

![oxm-exceptions](images/oxm-exceptions.png)