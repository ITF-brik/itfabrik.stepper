@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        'PSUseBOMForUnicodeEncodedFile',
        'PSAvoidUsingWriteHost',
        'PSAvoidOverwritingBuiltInCmdlets'
    )
}
