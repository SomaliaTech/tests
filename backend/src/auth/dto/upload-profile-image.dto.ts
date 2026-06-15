import { IsNotEmpty, IsString } from 'class-validator';

export class UploadProfileImageDto {
  @IsString()
  @IsNotEmpty()
  imageUrl: string;
}
