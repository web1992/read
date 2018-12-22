# xmlhttprequest

- [xmlhttprequest](https://javascript.info/xmlhttprequest)

```js
let xhr = new XMLHttpRequest();

xhr.open("GET", "/my/url");

xhr.send();

xhr.onload = function() {
  // we can check
  // status, statusText - for response HTTP status
  // responseText, responseXML (when content-type: text/xml) - for the response

  if (this.status != 200) {
    // handle error
    alert("error: " + this.status);
    return;
  }

  // get the response from this.responseText
};

xhr.onerror = function() {
  // handle error
};
```
