// Añadir al inicio del archivo, junto con el data source de la región
data "aws_caller_identity" "current" {}

// Crear rol que permite a las instancias conectarse por SSM
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
    Name = "Rol-SSM-Lab4"
  })
}

// Política para permitir acceso a Secrets Manager
resource "aws_iam_policy" "secretsmanager_policy" {
  name        = "${var.nombre_lab}_SecretsManagerPolicy"
  description = "Permisos para acceder a los secretos de PostgreSQL en Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "secretsmanager:GetSecretValue"
        ],
        Resource : [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:username_*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:password_*"
        ]
      }
    ]
  })
}
/*
// Política para permitir descifrado KMS
resource "aws_iam_policy" "kms_decrypt_policy" {
  name        = "${var.nombre_lab}_KMSDecryptPolicy"
  description = "Permisos para descifrar usando KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = [
          aws_kms_key.postgre_creds_key.arn
        ]
      }
    ]
  })
}

// Asociar la política de descifrado KMS al rol
resource "aws_iam_role_policy_attachment" "attach_kms_decrypt_policy" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = aws_iam_policy.kms_decrypt_policy.arn
}


*/
//Adjuntar la política de SSM al rol creado
resource "aws_iam_role_policy_attachment" "SSM" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// Asociar la política de Secrets Manager al rol creado
resource "aws_iam_role_policy_attachment" "attach_secretsmanager_policy" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = aws_iam_policy.secretsmanager_policy.arn
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
/*
//Adjuntar política de CloudFront al rol creado
resource "aws_iam_role_policy_attachment" "policy_CloudFront" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

//Adjuntar política de S3 para CloudFront al rol
resource "aws_iam_role_policy_attachment" "attach_cloudfront_s3_policy" {
  role       = aws_iam_role.rol_SSM.name
  policy_arn = aws_iam_policy.cloudfront_s3_policy.arn
}
*/

//Crear el perfil de instancia para el rol de SSM creado
resource "aws_iam_instance_profile" "profileSSM" {
  name = "${var.nombre_lab}_profileSSM"
  role = aws_iam_role.rol_SSM.name
  tags = merge(var.tags, {
    Name = "profileSSM-Lab4"
  })
}