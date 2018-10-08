# CHAPTER 14

## 
The upload flow for Droplr’s first version was woefully naïve:

- 1 Receive upload
- 2 Upload to S3
- 3 Create thumbnails if it’s an image
- 4 Reply to client applications