resource "aws_iam_user" "user" {
  name = "wsi-project-user"
}

resource "aws_iam_user_policy_attachment" "user" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}