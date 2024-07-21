import { GetObjectCommand, S3Client } from "@aws-sdk/client-s3";
import Sharp from 'sharp';

const S3 = new S3Client({region: 'ap-northeast-2'});
const BUCKET = 'wsi-static-arco';

const supportImageTypes = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'avif', 'tiff'];

export const handler = async(event, context, callback) => {
  const { request, response } = event.Records[0].cf;
  const { uri } = request;

  const ObjectKey = decodeURIComponent(uri).substring(1);
  const params = new URLSearchParams(request.querystring);
  let width = params.get('width');
  let height = params.get('height');

  if (!(width || height)) {
    return callback(null, response);
  }

  const extension = uri.match(/\/?(.*)\.(.*)/)[2].toLowerCase();
  width = parseInt(width, 10) || null;
  height = parseInt(height, 10) || null;

  let format = extension.toLowerCase();
  format = format === 'jpg' ? 'jpeg' : format;

  let s3Object;
  let resizedImage;

  if (!supportImageTypes.some(type => type === extension)) {
    responseHandler(
      403,
      'Forbidden',
      'Unsupported image type', [{
        key: 'Content-Type',
        value: 'text/plain'
      }],
    );

    return callback(null, response);
  }

  console.log(`width: ${width}, height: ${height}`);
  console.log('S3 Object key:', ObjectKey);

  try {
    const command = new GetObjectCommand({
      Bucket: BUCKET,
      Key: ObjectKey
    });
    s3Object = await S3.send(command);
  } catch (error) {
    responseHandler(
      404,
      'Not Found',
      'The image does not exist.', [{ key: 'Content-Type', value: 'text/plain' }],
    );
    return callback(null, response);
  }

  try {
    const imageBuffer = Buffer.concat(await s3Object.Body.toArray());

    resizedImage = await Sharp(imageBuffer)
      .resize(width, height)
      .toFormat(format)
      .withMetadata()
      .toBuffer();
  } catch (error) {
    responseHandler(
      500,
      'Internal Server Error',
      'Fail to resize image.', [{
        key: 'Content-Type',
        value: 'text/plain'
      }],
    );
    return callback(null, response);
  }

  responseHandler(
    200,
    'OK',
    resizedImage.toString('base64'), [{
      key: 'Content-Type',
      value: `image/${format}`
    },
    {
      key: 'Content-Length',
      value: resizedImage.length.toString()
    }],
    'base64'
  );

  function responseHandler(status, statusDescription, body, headers, bodyEncoding) {
    response.status = status;
    response.statusDescription = statusDescription;
    response.body = body;
    response.headers = headers.reduce((acc, header) => {
      acc[header.key.toLowerCase()] = [{ key: header.key, value: header.value }];
      return acc;
    }, {});
    if (bodyEncoding) {
      response.bodyEncoding = bodyEncoding;
    }
  }

  console.log('Success resizing image');

  return callback(null, response);
};
