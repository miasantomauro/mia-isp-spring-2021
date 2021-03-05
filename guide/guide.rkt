#lang forge

/*
  Sample Data for Custom Visualization Guide
  (https://docs.google.com/document/d/1CGvhezOA6BD7OMtoFPKf1Ao_meDOZiOX47OKu6Y8CjA/edit?usp=sharing)

  Mia Santomauro Spring 2021 ISP with Tim Nelson
  Adapted from binary_relation.rkt solution from Spring 2020
*/

sig Shape {
  next: lone Shape,
  color: one Color
}

abstract sig Color {}

sig Red extends Color {}
sig Green extends Color {}
sig Blue extends Color {}

pred rules {
    Color = Red + Green + Blue
}

run rules for exactly 5 Shape, exactly 3 Color for {next is linear}
