# spring bean parse

## BeanDefinitionParserDelegate.parseBeanDefinitionElement

```java
/**
 * Parses the supplied {@code <bean>} element. May return {@code null}
 * if there were errors during parse. Errors are reported to the
 * {@link org.springframework.beans.factory.parsing.ProblemReporter}.
 */
@Nullable
public BeanDefinitionHolder parseBeanDefinitionElement(Element ele, @Nullable BeanDefinition containingBean) {
String id = ele.getAttribute(ID_ATTRIBUTE);
String nameAttr = ele.getAttribute(NAME_ATTRIBUTE);
List<String> aliases = new ArrayList<>();
if (StringUtils.hasLength(nameAttr)) {
	String[] nameArr = StringUtils.tokenizeToStringArray(nameAttr, MULTI_VALUE_ATTRIBUTE_DELIMITERS);
	aliases.addAll(Arrays.asList(nameArr));
}
String beanName = id;
if (!StringUtils.hasText(beanName) && !aliases.isEmpty()) {
	beanName = aliases.remove(0);
	if (logger.isDebugEnabled()) {
		logger.debug("No XML 'id' specified - using '" + beanName +
				"' as bean name and " + aliases + " as aliases");
	}
}
if (containingBean == null) {
	checkNameUniqueness(beanName, aliases, ele);
}
AbstractBeanDefinition beanDefinition = parseBeanDefinitionElement(ele, beanName, containingBean);
if (beanDefinition != null) {
	if (!StringUtils.hasText(beanName)) {
		try {
			if (containingBean != null) {
				beanName = BeanDefinitionReaderUtils.generateBeanName(
						beanDefinition, this.readerContext.getRegistry(), true);
			}
			else {
				beanName = this.readerContext.generateBeanName(beanDefinition);
				// Register an alias for the plain bean class name, if still possible,
				// if the generator returned the class name plus a suffix.
				// This is expected for Spring 1.2/2.0 backwards compatibility.
				String beanClassName = beanDefinition.getBeanClassName();
				if (beanClassName != null &&
						beanName.startsWith(beanClassName) && beanName.length() > beanClassName.length() &&
						!this.readerContext.getRegistry().isBeanNameInUse(beanClassName)) {
					aliases.add(beanClassName);
				}
			}
			if (logger.isDebugEnabled()) {
				logger.debug("Neither XML 'id' nor 'name' specified - " +
						"using generated bean name [" + beanName + "]");
			}
		}
		catch (Exception ex) {
			error(ex.getMessage(), ele);
			return null;
		}
	}
	String[] aliasesArray = StringUtils.toStringArray(aliases);
	return new BeanDefinitionHolder(beanDefinition, beanName, aliasesArray);
}
return null;
}
```
