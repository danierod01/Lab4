//Crear rol de las instancias para conectarse por SSM
resource "aws_iam_role" "rol_SSM" {
  name = "${var.nombre_lab}_rol_SSM"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    additional_tag = "Rol-SSM-Lab4"
  })
}

//Adjuntar la política de SSM al rol creado
resource "aws_iam_role_policy_attachment" "SSM" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

//Crear el perfil de instancia para el rol de SSM creado
resource "aws_iam_instance_profile" "profileSSM" {
  name = "${var.nombre_lab}_profileSSM"
  role = aws_iam_role.rol_SSM.name
  tags = merge(var.tags, {
    additional_tag = "profileSSM-Lab4"
  })
}

//Adjuntar la política de Secrets al rol creado
resource "aws_iam_role_policy_attachment" "Secrets_policy" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

//Adjuntar política de KMS al rol creado
resource "aws_iam_role_policy_attachment" "policy_KMS" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}