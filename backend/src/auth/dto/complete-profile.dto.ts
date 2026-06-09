import { IsString, IsOptional, IsEmail, Length, IsUrl } from 'class-validator';

export class CompleteProfileDto {
  @IsString()
  @Length(2, 255)
  name: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsUrl()
  @IsOptional()
  profileImage?: string;
}
