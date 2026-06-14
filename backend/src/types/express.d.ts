declare global {
  namespace Express {
    namespace Multer {
      interface File {
        fieldname: string;
        originalname: string;
        encoding: string;
        mimetype: string;
        size: number;
        buffer: Buffer;
        stream: Readable;
        destination: string;
        filename: string;
        path: string;
      }
    }
  }
}

export {};
