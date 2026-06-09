import { IsString, IsOptional, IsEmail, Length } from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  @IsOptional()
  @Length(2, 255)
  name?: string;

  @IsEmail()
  @IsOptional()
  email?: string;
}
