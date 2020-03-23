# ResultSetHandler

## FastResultSetHandler

```java
  // FastResultSetHandler
  public List<Object> handleResultSets(Statement stmt) throws SQLException {
    final List<Object> multipleResults = new ArrayList<Object>();
    final List<ResultMap> resultMaps = mappedStatement.getResultMaps();
    int resultMapCount = resultMaps.size();
    int resultSetCount = 0;
    ResultSet rs = stmt.getResultSet();

    while (rs == null) {
      // move forward to get the first resultset in case the driver
      // doesn't return the resultset as the first result (HSQLDB 2.1)
      if (stmt.getMoreResults()) {
        rs = stmt.getResultSet();
      } else {
        if (stmt.getUpdateCount() == -1) {
          // no more results.  Must be no resultset
          break;
        }
      }
    }

    validateResultMapsCount(rs, resultMapCount);
    while (rs != null && resultMapCount > resultSetCount) {
      final ResultMap resultMap = resultMaps.get(resultSetCount);
      ResultColumnCache resultColumnCache = new ResultColumnCache(rs.getMetaData(), configuration);
      handleResultSet(rs, resultMap, multipleResults, resultColumnCache);
      rs = getNextResultSet(stmt);
      cleanUpAfterHandlingResultSet();
      resultSetCount++;
    }
    return collapseSingleResultList(multipleResults);
  }
```

## NestedResultSetHandler
