#!/bin/bash


aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1


aws iam create-role \
  --role-name Githubactions \
  --assume-role-policy-document file://policy.json


aws iam attach-role-policy \
  --role-name Githubactions \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess