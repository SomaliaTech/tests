import { Module } from '@nestjs/common';
import { HormuudService } from './hormuud.service';

@Module({
  providers: [HormuudService],
  exports: [HormuudService],
})
export class HormuudModule {}
