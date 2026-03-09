+++
title = "Document"
description = "SPDX 2.3 document model API reference"
weight = 3
+++

## Spdx::SpdxDocument

The root class representing an SPDX 2.3 document. Includes `JSON::Serializable`.

### Properties

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `spdx_version` | `String` | `spdxVersion` | SPDX spec version (e.g., `"SPDX-2.3"`) |
| `data_license` | `String` | `dataLicense` | Must be `"CC0-1.0"` |
| `spdx_id` | `String` | `SPDXID` | Must be `"SPDXRef-DOCUMENT"` |
| `name` | `String` | `name` | Document name |
| `document_namespace` | `String` | `documentNamespace` | Unique document URI |
| `creation_info` | `CreationInfo` | `creationInfo` | Creation metadata |
| `comment` | `String?` | `comment` | Optional comment |
| `external_document_refs` | `Array(ExternalDocumentRef)?` | `externalDocumentRefs` | References to other SPDX docs |
| `packages` | `Array(Package)?` | `packages` | Packages described |
| `files` | `Array(FileInfo)?` | `files` | Files described |
| `snippets` | `Array(Snippet)?` | `snippets` | Snippets described |
| `relationships` | `Array(Relationship)?` | `relationships` | Element relationships |
| `annotations` | `Array(Annotation)?` | `annotations` | Annotations |
| `extracted_licensing_infos` | `Array(ExtractedLicensingInfo)?` | `hasExtractedLicensingInfos` | Custom license definitions |
| `document_describes` | `Array(String)?` | `documentDescribes` | Top-level described elements |

### `#validate : Array(String)`

Returns a list of validation error messages. Empty if the document is valid.

Validation rules:

| Rule | Description |
|------|-------------|
| `spdxVersion` | Must be `"SPDX-2.3"` |
| `dataLicense` | Must be `"CC0-1.0"` |
| `SPDXID` | Must be `"SPDXRef-DOCUMENT"` |
| `name` | Must not be empty |
| `documentNamespace` | Must be a valid HTTP(S) URI |
| `creationInfo.created` | Must be ISO 8601 format (`YYYY-MM-DDThh:mm:ssZ`) |
| `creationInfo.creators` | Must not be empty; each must start with `Tool:`, `Organization:`, or `Person:` |
| SPDXID format | All SPDXIDs must match `SPDXRef-[a-zA-Z0-9.-]+` |
| DESCRIBES relationship | At least one DESCRIBES relationship is required |
| Package fields | `SPDXID`, `name`, `downloadLocation`, `licenseConcluded`, `licenseDeclared`, `copyrightText` required |
| Package verification code | Required when `filesAnalyzed` is `true` (default) |
| File fields | `SPDXID`, `fileName`, `licenseConcluded`, `copyrightText` required |
| Snippet fields | `SPDXID`, `snippetFromFile`, `ranges`, `licenseConcluded`, `copyrightText` required |
| Relationship fields | `spdxElementId`, `relatedSpdxElement` required |

### `#valid? : Bool`

Returns `true` if the document passes validation.

## Spdx::CreationInfo

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `created` | `String` | `created` | ISO 8601 timestamp |
| `creators` | `Array(String)` | `creators` | Creator identifiers (`Tool:`, `Organization:`, `Person:` prefix) |
| `license_list_version` | `String?` | `licenseListVersion` | SPDX license list version used |
| `comment` | `String?` | `comment` | Creator comment |

## Spdx::Package

| Property | Type | JSON Key | Required |
|----------|------|----------|----------|
| `spdx_id` | `String` | `SPDXID` | Yes |
| `name` | `String` | `name` | Yes |
| `download_location` | `String` | `downloadLocation` | Yes |
| `license_concluded` | `String` | `licenseConcluded` | Yes |
| `license_declared` | `String` | `licenseDeclared` | Yes |
| `copyright_text` | `String` | `copyrightText` | Yes |
| `version_info` | `String?` | `versionInfo` | No |
| `package_file_name` | `String?` | `packageFileName` | No |
| `supplier` | `String?` | `supplier` | No |
| `originator` | `String?` | `originator` | No |
| `files_analyzed` | `Bool?` | `filesAnalyzed` | No (default: `true`) |
| `package_verification_code` | `PackageVerificationCode?` | `packageVerificationCode` | Conditional |
| `checksums` | `Array(Checksum)?` | `checksums` | No |
| `homepage` | `String?` | `homepage` | No |
| `source_info` | `String?` | `sourceInfo` | No |
| `license_info_from_files` | `Array(String)?` | `licenseInfoFromFiles` | No |
| `license_comments` | `String?` | `licenseComments` | No |
| `summary` | `String?` | `summary` | No |
| `description` | `String?` | `description` | No |
| `comment` | `String?` | `comment` | No |
| `external_refs` | `Array(ExternalRef)?` | `externalRefs` | No |
| `attribution_texts` | `Array(String)?` | `attributionTexts` | No |
| `primary_package_purpose` | `PrimaryPackagePurpose?` | `primaryPackagePurpose` | No |
| `release_date` | `String?` | `releaseDate` | No |
| `built_date` | `String?` | `builtDate` | No |
| `valid_until_date` | `String?` | `validUntilDate` | No |

## Spdx::PrimaryPackagePurpose

Enum for package purpose classification per SPDX 2.3:

`APPLICATION`, `FRAMEWORK`, `LIBRARY`, `CONTAINER`, `OPERATING_SYSTEM`, `DEVICE`, `FIRMWARE`, `SOURCE`, `ARCHIVE`, `FILE`, `INSTALL`, `OTHER`

```crystal
purpose = Spdx::PrimaryPackagePurpose.from_string("LIBRARY")
purpose.to_s  # => "LIBRARY"
```

Note: `OPERATING_SYSTEM` serializes as `"OPERATING-SYSTEM"` in JSON and Tag-Value.

## Spdx::FileInfo

| Property | Type | JSON Key |
|----------|------|----------|
| `spdx_id` | `String` | `SPDXID` |
| `file_name` | `String` | `fileName` |
| `file_types` | `Array(FileType)?` | `fileTypes` |
| `checksums` | `Array(Checksum)?` | `checksums` |
| `license_concluded` | `String` | `licenseConcluded` |
| `license_info_in_files` | `Array(String)?` | `licenseInfoInFiles` |
| `copyright_text` | `String` | `copyrightText` |
| `comment` | `String?` | `comment` |
| `notice_text` | `String?` | `noticeText` |
| `file_contributors` | `Array(String)?` | `fileContributors` |
| `attribution_texts` | `Array(String)?` | `attributionTexts` |

## Spdx::FileType

Enum for file type classification per SPDX 2.3:

`SOURCE`, `BINARY`, `ARCHIVE`, `APPLICATION`, `AUDIO`, `IMAGE`, `TEXT`, `VIDEO`, `DOCUMENTATION`, `SPDX`, `OTHER`

```crystal
ft = Spdx::FileType.from_string("SOURCE")
ft.to_s  # => "SOURCE"
```

## Spdx::Snippet

| Property | Type | JSON Key |
|----------|------|----------|
| `spdx_id` | `String` | `SPDXID` |
| `snippet_from_file` | `String` | `snippetFromFile` |
| `ranges` | `Array(SnippetRange)` | `ranges` |
| `license_concluded` | `String` | `licenseConcluded` |
| `copyright_text` | `String` | `copyrightText` |
| `license_info_in_snippets` | `Array(String)?` | `licenseInfoInSnippets` |
| `name` | `String?` | `name` |
| `comment` | `String?` | `comment` |
| `license_comments` | `String?` | `licenseComments` |
| `attribution_texts` | `Array(String)?` | `attributionTexts` |

## Spdx::Relationship

| Property | Type | JSON Key |
|----------|------|----------|
| `spdx_element_id` | `String` | `spdxElementId` |
| `relationship_type` | `RelationshipType` | `relationshipType` |
| `related_spdx_element` | `String` | `relatedSpdxElement` |
| `comment` | `String?` | `comment` |

## Spdx::RelationshipType

Enum with 44 relationship types:

`DESCRIBES`, `DESCRIBED_BY`, `CONTAINS`, `CONTAINED_BY`, `DEPENDS_ON`, `DEPENDENCY_OF`, `GENERATES`, `GENERATED_FROM`, `ANCESTOR_OF`, `DESCENDANT_OF`, `VARIANT_OF`, `DISTRIBUTION_ARTIFACT`, `PATCH_FOR`, `COPY_OF`, `FILE_ADDED`, `FILE_DELETED`, `FILE_MODIFIED`, `EXPANDED_FROM_ARCHIVE`, `DYNAMIC_LINK`, `STATIC_LINK`, `DATA_FILE_OF`, `TEST_CASE_OF`, `BUILD_TOOL_OF`, `DEV_TOOL_OF`, `TEST_OF`, `TEST_TOOL_OF`, `DOCUMENTATION_OF`, `OPTIONAL_COMPONENT_OF`, `GENERATED_FROM_COPY`, `PACKAGE_OF`, `HAS_PREREQUISITE`, `PREREQUISITE_FOR`, `OTHER`, `RUNTIME_DEPENDENCY_OF`, `DEV_DEPENDENCY_OF`, `OPTIONAL_DEPENDENCY_OF`, `PROVIDED_DEPENDENCY_OF`, `TEST_DEPENDENCY_OF`, `BUILD_DEPENDENCY_OF`, `EXAMPLE_OF`, `GENERATES_COPY`, `REQUIREMENT_DESCRIPTION_FOR`, `SPECIFICATION_FOR`, `VARIANT_DISTRIBUTION_OF`, `SECURITY_FIX_FOR`, `AFFECTS`

## Spdx::ChecksumAlgorithm

Enum: `SHA1`, `SHA224`, `SHA256`, `SHA384`, `SHA512`, `SHA3_256`, `SHA3_384`, `SHA3_512`, `BLAKE2b_256`, `BLAKE2b_384`, `BLAKE2b_512`, `BLAKE3`, `MD2`, `MD4`, `MD5`, `MD6`, `ADLER32`

## Spdx::Checksum

| Property | Type | JSON Key |
|----------|------|----------|
| `algorithm` | `ChecksumAlgorithm` | `algorithm` |
| `value` | `String` | `checksumValue` |

## Spdx::Annotation

| Property | Type | JSON Key |
|----------|------|----------|
| `annotation_date` | `String` | `annotationDate` |
| `annotation_type` | `AnnotationType` | `annotationType` |
| `annotator` | `String` | `annotator` |
| `comment` | `String` | `comment` |
| `spdx_element_id` | `String?` | `spdxElementId` |

## Spdx::ExternalRef

| Property | Type | JSON Key |
|----------|------|----------|
| `reference_category` | `ExternalRefCategory` | `referenceCategory` |
| `reference_type` | `String` | `referenceType` |
| `reference_locator` | `String` | `referenceLocator` |
| `comment` | `String?` | `comment` |

## Spdx::ExternalRefCategory

Enum for external reference categories per SPDX 2.3:

`SECURITY`, `PACKAGE_MANAGER`, `PERSISTENT_ID`, `OTHER`

```crystal
cat = Spdx::ExternalRefCategory.from_string("PACKAGE-MANAGER")
cat.to_s  # => "PACKAGE-MANAGER"
```

Note: `PACKAGE_MANAGER` serializes as `"PACKAGE-MANAGER"` and `PERSISTENT_ID` as `"PERSISTENT-ID"`.

## Spdx::ExternalDocumentRef

| Property | Type | JSON Key |
|----------|------|----------|
| `external_document_id` | `String` | `externalDocumentId` |
| `spdx_document` | `String` | `spdxDocument` |
| `checksum` | `Checksum` | `checksum` |

## Spdx::ExtractedLicensingInfo

| Property | Type | JSON Key |
|----------|------|----------|
| `license_id` | `String` | `licenseId` |
| `extracted_text` | `String` | `extractedText` |
| `name` | `String?` | `name` |
| `comment` | `String?` | `comment` |
| `see_alsos` | `Array(String)?` | `seeAlsos` |

## Spdx::PackageVerificationCode

| Property | Type | JSON Key |
|----------|------|----------|
| `value` | `String` | `packageVerificationCodeValue` |
| `excluded_files` | `Array(String)?` | `packageVerificationCodeExcludedFiles` |
