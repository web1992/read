# View Technologies

- 1 [Introduction](#introduction)
- 2 [Context configuration](#context-configuration)
- 3 [Advanced configuration](#advanced-configuration)
- 4 [Document views: PDF, Excel](#document-views:-pdf,-excel)

## Introduction

One of the areas in which Spring excels is in the separation of view technologies from the rest of the MVC framework. For example, deciding to use Groovy Markup Templates or Thymeleaf in place of an existing JSP is primarily a matter of configuration. This chapter covers the major view technologies that work with Spring and touches briefly on how to add new ones. This chapter assumes you are already familiar with [Section 22.5](https://docs.spring.io/spring/docs/4.3.x/spring-framework-reference/htmlsingle/#mvc-viewresolver), “Resolving views” which covers the basics of how views in general are coupled to the MVC framework.

- Thymeleaf
- Groovy Markup
- Velocity & FreeMarker

## Context configuration

 ```xml
 <!--
This bean sets up the Velocity environment for us based on a root path for templates.
Optionally, a properties file can be specified for more control over the Velocity
environment, but the defaults are pretty sane for file based template loading.
-->
<bean id="velocityConfig" class="org.springframework.web.servlet.view.velocity.VelocityConfigurer">
    <property name="resourceLoaderPath" value="/WEB-INF/velocity/"/>
</bean>

<!--
View resolvers can also be configured with ResourceBundles or XML files. If you need
different view resolving based on Locale, you have to use the resource bundle resolver.
-->
<bean id="viewResolver" class="org.springframework.web.servlet.view.velocity.VelocityViewResolver">
    <property name="cache" value="true"/>
    <property name="prefix" value=""/>
    <property name="suffix" value=".vm"/>
</bean>
 ```

 ```xml
 <!-- freemarker config -->
<bean id="freemarkerConfig" class="org.springframework.web.servlet.view.freemarker.FreeMarkerConfigurer">
    <property name="templateLoaderPath" value="/WEB-INF/freemarker/"/>
</bean>

<!--
View resolvers can also be configured with ResourceBundles or XML files. If you need
different view resolving based on Locale, you have to use the resource bundle resolver.
-->
<bean id="viewResolver" class="org.springframework.web.servlet.view.freemarker.FreeMarkerViewResolver">
    <property name="cache" value="true"/>
    <property name="prefix" value=""/>
    <property name="suffix" value=".ftl"/>
</bean>
 ```

## Advanced configuration

`velocity.properties`

```xml
<bean id="velocityConfig" class="org.springframework.web.servlet.view.velocity.VelocityConfigurer">
    <property name="configLocation" value="/WEB-INF/velocity.properties"/>
</bean>
```

Alternatively, you can specify velocity properties directly in the bean definition for the Velocity config bean by replacing the "configLocation" property with the following inline properties.

```xml
<bean id="velocityConfig" class="org.springframework.web.servlet.view.velocity.VelocityConfigurer">
    <property name="velocityProperties">
        <props>
            <prop key="resource.loader">file</prop>
            <prop key="file.resource.loader.class">
                org.apache.velocity.runtime.resource.loader.FileResourceLoader
            </prop>
            <prop key="file.resource.loader.path">${webapp.root}/WEB-INF/velocity</prop>
            <prop key="file.resource.loader.cache">false</prop>
        </props>
    </property>
</bean>
```

## Document views: PDF, Excel

Excel views

```java
package excel;

// imports omitted for brevity

public class HomePage extends AbstractExcelView {

    protected void buildExcelDocument(Map model, HSSFWorkbook wb, HttpServletRequest req,
            HttpServletResponse resp) throws Exception {

        HSSFSheet sheet;
        HSSFRow sheetRow;
        HSSFCell cell;

        // Go to the first sheet
        // getSheetAt: only if wb is created from an existing document
        // sheet = wb.getSheetAt(0);
        sheet = wb.createSheet("Spring");
        sheet.setDefaultColumnWidth((short) 12);

        // write a text at A1
        cell = getCell(sheet, 0, 0);
        setText(cell, "Spring-Excel test");

        List words = (List) model.get("wordList");
        for (int i=0; i < words.size(); i++) {
            cell = getCell(sheet, 2+i, 0);
            setText(cell, (String) words.get(i));
        }
    }

}
```

`AbstractJExcelView`

```java
package excel;

// imports omitted for brevity

public class HomePage extends AbstractJExcelView {

    protected void buildExcelDocument(Map model, WritableWorkbook wb,
            HttpServletRequest request, HttpServletResponse response) throws Exception {

        WritableSheet sheet = wb.createSheet("Spring", 0);

        sheet.addCell(new Label(0, 0, "Spring-Excel test"));

        List words = (List) model.get("wordList");
        for (int i = 0; i < words.size(); i++) {
            sheet.addCell(new Label(2+i, 0, (String) words.get(i)));
        }
    }
}
```

`PDF views`

```java
package pdf;

// imports omitted for brevity

public class PDFPage extends AbstractPdfView {

    protected void buildPdfDocument(Map model, Document doc, PdfWriter writer,
        HttpServletRequest req, HttpServletResponse resp) throws Exception {
        List words = (List) model.get("wordList");
        for (int i=0; i<words.size(); i++) {
            doc.add( new Paragraph((String) words.get(i)));
        }
    }

}
``

- JasperReports
- Feed views: RSS, Atom
- JSON Mapping View
- XML Mapping View
