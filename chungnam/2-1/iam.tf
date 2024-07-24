resource "aws_iam_user" "admin" {
  name = "Admin"
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "employee" {
  name = "Employee"
}

resource "aws_iam_user_policy_attachment" "employee" {
  user       = aws_iam_user.employee.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}