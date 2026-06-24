// export class NotificationModel extends Notification {
//   static fromJson(json: any): NotificationModel {
//     const notification = new NotificationModel();
//     notification.id = json.id;
//     notification.userId = json.userId;
//     notification.type = json.type as NotificationType;
//     notification.title = json.title;
//     notification.message = json.message;
//     notification.isRead = json.isRead ?? false;
//     notification.actionText = json.actionText;
//     notification.actionLink = json.actionLink;
//     notification.createdAt = json.createdAt
//       ? new Date(json.createdAt)
//       : new Date();
//     notification.updatedAt = json.updatedAt
//       ? new Date(json.updatedAt)
//       : new Date();
//     return notification;
//   }

//   toJson(): any {
//     return {
//       id: this.id,
//       userId: this.userId,
//       type: this.type,
//       title: this.title,
//       message: this.message,
//       isRead: this.isRead,
//       actionText: this.actionText,
//       actionLink: this.actionLink,
//       createdAt: this.createdAt,
//       updatedAt: this.updatedAt,
//     };
//   }
// }
