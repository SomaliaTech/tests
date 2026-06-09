import { IsString, IsUrl } from 'class-validator';

export class UploadProfileImageDto {
  @IsUrl()
  imageUrl: string;
}
