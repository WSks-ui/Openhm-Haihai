
export class User {
  id: string;
  username: string;
  avatar: string; // Resource path or URL
  bgImage: string; // Resource path or URL
  bio: string;
  gender: string;
  birthday: string;

  constructor(id: string, username: string, avatar: string, bgImage: string, bio: string, gender: string, birthday: string) {
    this.id = id;
    this.username = username;
    this.avatar = avatar;
    this.bgImage = bgImage;
    this.bio = bio;
    this.gender = gender;
    this.birthday = birthday;
  }
}

export const currentUser = new User(
  '888888',
  '我的名字',
  'app.media.startIcon',
  'app.media.background',
  '温暖的思考，温柔的生活。',
  '保密',
  '2000-01-01'
);
