# MappedFile

## MappedFileQueue

topicQueueTable

## MappedFileQueue#findMappedFileByOffset

## MappedFile.init

```java
// MappedFile#init
private void init(final String fileName, final int fileSize) throws IOException {
    this.fileName = fileName;
    this.fileSize = fileSize;
    this.file = new File(fileName);
    this.fileFromOffset = Long.parseLong(this.file.getName());
    boolean ok = false;
    ensureDirOK(this.file.getParent());
    try {
        this.fileChannel = new RandomAccessFile(this.file, "rw").getChannel();
        this.mappedByteBuffer = this.fileChannel.map(MapMode.READ_WRITE, 0, fileSize);
        TOTAL_MAPPED_VIRTUAL_MEMORY.addAndGet(fileSize);
        TOTAL_MAPPED_FILES.incrementAndGet();
        ok = true;
    } catch (FileNotFoundException e) {
        log.error("Failed to create file " + this.fileName, e);
        throw e;
    } catch (IOException e) {
        log.error("Failed to map file " + this.fileName, e);
        throw e;
    } finally {
        if (!ok && this.fileChannel != null) {
            this.fileChannel.close();
        }
    }
}
```

## MappedFile getLastMappedFile

`MappedFile` 文件的创建过程

```java
// 从 CopyOnWriteArrayList<MappedFile> mappedFileSize 获取文件
public MappedFile getLastMappedFile() {

}
// 从 mappedFileSize 获取 MappedFile，如果没有则创建
public MappedFile getLastMappedFile(final long startOffset, boolean needCreate) {
        long createOffset = -1;
        MappedFile mappedFileLast = getLastMappedFile();

        if (mappedFileLast == null) {
            createOffset = startOffset - (startOffset % this.mappedFileSize);
        }

        if (mappedFileLast != null && mappedFileLast.isFull()) {
            createOffset = mappedFileLast.getFileFromOffset() + this.mappedFileSize;
        }

        if (createOffset != -1 && needCreate) {
            String nextFilePath = this.storePath + File.separator + UtilAll.offset2FileName(createOffset);
            String nextNextFilePath = this.storePath + File.separator
                + UtilAll.offset2FileName(createOffset + this.mappedFileSize);
            MappedFile mappedFile = null;

            if (this.allocateMappedFileService != null) {
                mappedFile = this.allocateMappedFileService.putRequestAndReturnMappedFile(nextFilePath,
                    nextNextFilePath, this.mappedFileSize);
            } else {
                try {
                    mappedFile = new MappedFile(nextFilePath, this.mappedFileSize);
                } catch (IOException e) {
                    log.error("create mappedFile exception", e);
                }
            }

            if (mappedFile != null) {
                if (this.mappedFiles.isEmpty()) {
                    mappedFile.setFirstCreateInQueue(true);
                }
                this.mappedFiles.add(mappedFile);
            }

            return mappedFile;
        }

        return mappedFileLast;
}
```

## MappedFile Position

```java
// wrotePosition 每次写入数据的时候，就会发生变化
protected final AtomicInteger wrotePosition = new AtomicInteger(0);
protected final AtomicInteger committedPosition = new AtomicInteger(0);
private final AtomicInteger flushedPosition = new AtomicInteger(0);
```

## appendMessagesInner#appendMessagesInner

```java
// appendMessagesInner 追加消息到文件中
// 通过 AppendMessageCallback（回调）实现 
public AppendMessageResult appendMessagesInner(final MessageExt messageExt, final AppendMessageCallback cb) {
    assert messageExt != null;
    assert cb != null;
    int currentPos = this.wrotePosition.get();
    if (currentPos < this.fileSize) {
        ByteBuffer byteBuffer = writeBuffer != null ? writeBuffer.slice() : this.mappedByteBuffer.slice();
        byteBuffer.position(currentPos);
        AppendMessageResult result;
        if (messageExt instanceof MessageExtBrokerInner) {
            result = cb.doAppend(this.getFileFromOffset(), byteBuffer, this.fileSize - currentPos, (MessageExtBrokerInner) messageExt);
        } else if (messageExt instanceof MessageExtBatch) {
            result = cb.doAppend(this.getFileFromOffset(), byteBuffer, this.fileSize - currentPos, (MessageExtBatch) messageExt);
        } else {
            return new AppendMessageResult(AppendMessageStatus.UNKNOWN_ERROR);
        }
        this.wrotePosition.addAndGet(result.getWroteBytes());
        this.storeTimestamp = result.getStoreTimestamp();
        return result;
    }
    log.error("MappedFile.appendMessage return null, wrotePosition: {} fileSize: {}", currentPos, this.fileSize);
    return new AppendMessageResult(AppendMessageStatus.UNKNOWN_ERROR);
}
```

## MappedFile flush

```java
// 把内存强制刷新到磁盘中，会更新 flushedPosition 的值
public int flush(final int flushLeastPages) {
    if (this.isAbleToFlush(flushLeastPages)) {
        if (this.hold()) {
            int value = getReadPosition();
            try {
                //We only append data to fileChannel or mappedByteBuffer, never both.
                if (writeBuffer != null || this.fileChannel.position() != 0) {
                    this.fileChannel.force(false);
                } else {
                    this.mappedByteBuffer.force();
                }
            } catch (Throwable e) {
                log.error("Error occurred when force data to disk.", e);
            }
            this.flushedPosition.set(value);
            this.release();
        } else {
            log.warn("in flush, hold failed, flush offset = " + this.flushedPosition.get());
            this.flushedPosition.set(getReadPosition());
        }
    }
    return this.getFlushedPosition();
}
```

## MappedFile isAbleToCommit

```java
protected boolean isAbleToCommit(final int commitLeastPages) {
    int flush = this.committedPosition.get();
    int write = this.wrotePosition.get();
    if (this.isFull()) {
        return true;
    }
    if (commitLeastPages > 0) {
        return ((write / OS_PAGE_SIZE) - (flush / OS_PAGE_SIZE)) >= commitLeastPages;
    }
    return write > flush;
}
```
