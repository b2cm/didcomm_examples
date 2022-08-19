import 'package:dart_ssi/credentials.dart';
import 'package:json_path/json_path.dart';
import 'package:json_schema2/json_schema2.dart';

var dresdenPass = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - ALG2Bescheid',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'ALG2Bescheid'}
            }))
      ])),
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - WohngeldBescheid',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'WohngeldBescheid'}
            }))
      ])),
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Kinderzuschlag',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Kinderzuschlag'}
            }))
      ])),
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Altersgrundsicherung',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Altersgrundsicherung'}
            }))
      ])),
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Jugendhilfe',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Jugendhilfe'}
            }))
      ])),
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Asylleistungen',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Asylleistungen'}
            }))
      ]))
], submissionRequirement: [
  SubmissionRequirement(
      rule: SubmissionRequirementRule.pick,
      count: 1,
      from: 'A',
      name: 'Dresden Pass Berechtigung')
]);

var museum = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Nachweis Ermäßigungsberechtigung',
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'StudentCard'}
            }))
      ])),
  InputDescriptor(
      group: ['A'],
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'DresdenPass'}
            }))
      ]))
], submissionRequirement: [
  SubmissionRequirement(
      rule: SubmissionRequirementRule.pick,
      count: 1,
      from: 'A',
      name: 'Ermäßigungsberechtigung')
]);

var alg2 = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - ALG2Bescheid',
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'ALG2Bescheid'}
            }))
      ]))
]);

var kinderzuschlag = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Kinderzuschlag',
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Kinderzuschlag'}
            }))
      ]))
]);

var wohngeld = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - WohngeldBescheid',
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'WohngeldBescheid'}
            }))
      ]))
]);

var asyl = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Asylleistungen',
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Asylleistungen'}
            }))
      ]))
]);

var jugend = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Jugendhilfe',
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Jugendhilfe'}
            }))
      ]))
]);
var alter = PresentationDefinition(inputDescriptors: [
  InputDescriptor(
      purpose: 'Berechtigung DresdenPass - Altersgrundsicherung',
      constraints: InputDescriptorConstraints(fields: [
        InputDescriptorField(
            path: [JsonPath(r'$..type')],
            filter: JsonSchema.createSchema({
              'type': 'array',
              'contains': {'type': 'string', 'pattern': 'Altersgrundsicherung'}
            }))
      ]))
]);
