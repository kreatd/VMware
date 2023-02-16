

$newdscluster.extensiondata|%{(get-view (Get-View ServiceInstance).Content.StorageResourceManager).RefreshStorageDrsRecommendation($_.moref)}

$si = get-view ServiceInstance
$vimService = $si.client.vimservice

foreach ($ds in $datastores)
{
$spec = New-Object VMware.Vim.StorageIORMConfigSpec
$spec.congestionThreshold = 20
$spec.congestionThresholdMode = "manual"
$spec.enabled = $true
$taskmoref = $vimservice.configureDatastoreIORM_Task([VMware.Vim.VIConvert]::ToVim51($si.content.StorageResourceManager), [VMware.Vim.VIConvert]::ToVim51($ds.extensiondata.moref), [VMware.Vim.VIConvert]::ToVim51($spec))
}
#$spec.PercentOfPeakThroughput = 60
# SIG # Begin signature block
# MIIidQYJKoZIhvcNAQcCoIIiZjCCImICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFMmA+ZPhj6dVttjFuspYP9ov
# hTmgghyAMIIG2zCCBMOgAwIBAgITUQAAB8wgIhgrZ6tMCAAAAAAHzDANBgkqhkiG
# 9w0BAQsFADBXMRMwEQYKCZImiZPyLGQBGRYDbmV0MRYwFAYKCZImiZPyLGQBGRYG
# dXBtY2hzMRQwEgYKCZImiZPyLGQBGRYEYWNjdDESMBAGA1UEAxMJVVBNQy1DQTIw
# MB4XDTE5MDkxODE2MjIyNFoXDTIyMDkxNzE2MjIyNFowEjEQMA4GA1UEAxMHYnVy
# dG9uZDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMNBAiyz0gp+Fag0
# Uka0TuewBON7Ia4GvuBAr/hRYV15/bzKf0cEdJe9InUdgkg39uIQahg5+vUG+pu7
# JhCJ0XmYOCWitaXbqWj5neWojaFaTDz9hXTIsmFgOgOVZDAXTs9fiLv1Obg7PMxW
# nARj/GoqlnZbGIpNcZEhAg1dtUvI/JjCXr1LyN10UZhk35mfE+uh7s3AizI1xBrc
# O8NMcpd7cjuiiPwepTtEnem3T23y8DhwvqXaGTuh8O3r0t6t3Gz99k3f7up5ThF5
# quieCFroSOHIzfLGvIXcVK1iGCsl0ecyr6oKuqYIIB0bhabIOJaerxvHwFk7Tqz/
# TB6GUb8CAwEAAaOCAuMwggLfMD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcVCIP7
# 4xmFx8BLh9WBK4LhrE+HjPdOPob5+j6D3oRIAgFkAgEMMB0GA1UdJQQWMBQGCCsG
# AQUFBwMIBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwJwYJKwYBBAGCNxUKBBowGDAK
# BggrBgEFBQcDCDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUta3MfTB8KdAazI+Gdh8x
# 0yG7UVcwGwYDVR0RBBQwEoEQYnVydG9uZEB1cG1jLmVkdTAfBgNVHSMEGDAWgBT4
# DKT2a8zdfxr3pxPCy7TDSIDMOjCB9wYDVR0fBIHvMIHsMIHpoIHmoIHjhilodHRw
# Oi8vdXBtY2NybC51cG1jLmNvbS9DRFAvVVBNQy1DQTIwLmNybIaBtWxkYXA6Ly8v
# Q049VVBNQy1DQTIwLENOPVdJTlBLSU5TUFJEMDMsQ049Q0RQLENOPVB1YmxpYyUy
# MEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9
# dXBtY2hzLERDPW5ldD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgfEGCCsGAQUFBwEBBIHkMIHh
# MIGnBggrBgEFBQcwAoaBmmxkYXA6Ly8vQ049VVBNQy1DQTIwLENOPUFJQSxDTj1Q
# dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
# aW9uLERDPXVwbWNocyxEQz1uZXQ/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENs
# YXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwNQYIKwYBBQUHMAGGKWh0dHA6Ly91
# cG1jY3JsLnVwbWMuY29tL0NEUC9VUE1DLUNBMjAuY3J0MA0GCSqGSIb3DQEBCwUA
# A4ICAQA3wXWJ6lYxW6xoW7vg/tKMFzVhANFNkwxdTt5cAmGE2V83Aj2JhLz/MVf4
# PxaYM8/wdOdAIg3Rqtibzpk2J1cRig16futz7rN2l4XJnKiPq7LFQaFVXTmjSzfS
# oX8p46+ddjQHe2t9oypgryDC5NZRNtLHIZ4AWT21uAee94STjXzBzcCf8OWYIht3
# pYqf0zf3XFkcS0bjZX+ZFSd24HaF8jdxAsdyGWWtfOjglRoDvE5pIUJXDf2huQsN
# QQPm7FmJm9Q/73qiufxsZeuLiFyiHJBPqSSL38eGCzuUa2m3C6C7avGHY3K+RUcx
# ClwAA++9FRXCvwM9oxxOy9eV594kfIhonTl5hvjgCY49YZ8IMjHhzbobAq9jmz9g
# ZKOVQR00HmSNxiwPlZrRp4AutRby5UpyUR20HxMkzhrDoSBkU8w6nkbwKNlYlz6t
# j9FyJxqagQ+mSpnMVDG7teFissfpTT4jkmNjopIIg6F7xHc8NLm8yOpZTFSx9RGp
# IFUHTMJkkNQXGgLZvn06kObYbjEGinWwcXUJqQx+eM2duTuN4NefkAJqDXa0shqQ
# Yv9VICuofYxyV/JYdi9ulwbGvPFQjwSdsqZGYhJvqMop3+CE8CzEzqJYIigqbS/2
# cgSc7ZzVUVvg5ImByFR4YkPspLDYaqb9bjErJcXXW2XT2NzWjjCCBuwwggTUoAMC
# AQICEDAPb6zdZph0fKlGNqd4LbkwDQYJKoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEe
# MBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1
# c3QgUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE5MDUwMjAwMDAwMFoX
# DTM4MDExODIzNTk1OVowfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIg
# TWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBM
# aW1pdGVkMSUwIwYDVQQDExxTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIENBMIIC
# IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyBsBr9ksfoiZfQGYPyCQvZyA
# IVSTuc+gPlPvs1rAdtYaBKXOR4O168TMSTTL80VlufmnZBYmCfvVMlJ5LsljwhOb
# toY/AQWSZm8hq9VxEHmH9EYqzcRaydvXXUlNclYP3MnjU5g6Kh78zlhJ07/zObu5
# pCNCrNAVw3+eolzXOPEWsnDTo8Tfs8VyrC4Kd/wNlFK3/B+VcyQ9ASi8Dw1Ps5EB
# jm6dJ3VV0Rc7NCF7lwGUr3+Az9ERCleEyX9W4L1GnIK+lJ2/tCCwYH64TfUNP9vQ
# 6oWMilZx0S2UTMiMPNMUopy9Jv/TUyDHYGmbWApU9AXn/TGs+ciFF8e4KRmkKS9G
# 493bkV+fPzY+DjBnK0a3Na+WvtpMYMyou58NFNQYxDCYdIIhz2JWtSFzEh79qsoI
# WId3pBXrGVX/0DlULSbuRRo6b83XhPDX8CjFT2SDAtT74t7xvAIo9G3aJ4oG0paH
# 3uhrDvBbfel2aZMgHEqXLHcZK5OVmJyXnuuOwXhWxkQl3wYSmgYtnwNe/YOiU2fK
# sfqNoWTJiJJZy6hGwMnypv99V9sSdvqKQSTUG/xypRSi1K1DHKRJi0E5FAMeKfob
# pSKupcNNgtCN2mu32/cYQFdz8HGj+0p9RTbB942C+rnJDVOAffq2OVgy728YUInX
# T50zvRq1naHelUF6p4MCAwEAAaOCAVowggFWMB8GA1UdIwQYMBaAFFN5v1qqK0rP
# VIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQaofhhGSAPw0F3RSiO0TVfBhIEVTAOBgNV
# HQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEF
# BQcDCDARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDov
# L2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25BdXRo
# b3JpdHkuY3JsMHYGCCsGAQUFBwEBBGowaDA/BggrBgEFBQcwAoYzaHR0cDovL2Ny
# dC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsG
# AQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUA
# A4ICAQBtVIGlM10W4bVTgZF13wN6MgstJYQRsrDbKn0qBfW8Oyf0WqC5SVmQKWxh
# y7VQ2+J9+Z8A70DDrdPi5Fb5WEHP8ULlEH3/sHQfj8ZcCfkzXuqgHCZYXPO0EQ/V
# 1cPivNVYeL9IduFEZ22PsEMQD43k+ThivxMBxYWjTMXMslMwlaTW9JZWCLjNXH8B
# lr5yUmo7Qjd8Fng5k5OUm7Hcsm1BbWfNyW+QPX9FcsEbI9bCVYRm5LPFZgb289ZL
# Xq2jK0KKIZL+qG9aJXBigXNjXqC72NzXStM9r4MGOBIdJIct5PwC1j53BLwENrXn
# d8ucLo0jGLmjwkcd8F3WoXNXBWiap8k3ZR2+6rzYQoNDBaWLpgn/0aGUpk6qPQn1
# BWy30mRa2Coiwkud8TleTN5IPZs0lpoJX47997FSkc4/ifYcobWpdR9xv1tDXWU9
# UIFuq/DQ0/yysx+2mZYm9Dx5i1xkzM3uJ5rloMAMcofBbk1a0x7q8ETmMm8c6xdO
# lMN4ZSA7D0GqH+mhQZ3+sbigZSo04N6o+TzmwTC7wKBjLPxcFgCo0MR/6hGdHgbG
# pm0yXbQ4CStJB6r97DDa8acvz7f9+tCjhNknnvsBZne5VhDhIG7GrrH5trrINV0z
# do7xfCAMKneutaIChrop7rRaALGMq+P5CslUXdS5anSevUiumDCCBwcwggTvoAMC
# AQICEQCMd6AAj/TRsMY9nzpIg41rMA0GCSqGSIb3DQEBDAUAMH0xCzAJBgNVBAYT
# AkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZv
# cmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBS
# U0EgVGltZSBTdGFtcGluZyBDQTAeFw0yMDEwMjMwMDAwMDBaFw0zMjAxMjIyMzU5
# NTlaMIGEMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLDAq
# BgNVBAMMI1NlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgU2lnbmVyICMyMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAkYdLLIvB8R6gntMHxgHKUrC+eXld
# CWYGLS81fbvA+yfaQmpZGyVM6u9A1pp+MshqgX20XD5WEIE1OiI2jPv4ICmHrHTQ
# G2K8P2SHAl/vxYDvBhzcXk6Th7ia3kwHToXMcMUNe+zD2eOX6csZ21ZFbO5LIGzJ
# Pmz98JvxKPiRmar8WsGagiA6t+/n1rglScI5G4eBOcvDtzrNn1AEHxqZpIACTR0F
# qFXTbVKAg+ZuSKVfwYlYYIrv8azNh2MYjnTLhIdBaWOBvPYfqnzXwUHOrat2iyCA
# 1C2VB43H9QsXHprl1plpUcdOpp0pb+d5kw0yY1OuzMYpiiDBYMbyAizE+cgi3/kn
# gqGDUcK8yYIaIYSyl7zUr0QcloIilSqFVK7x/T5JdHT8jq4/pXL0w1oBqlCli3aV
# G2br79rflC7ZGutMJ31MBff4I13EV8gmBXr8gSNfVAk4KmLVqsrf7c9Tqx/2RJzV
# mVnFVmRb945SD2b8mD9EBhNkbunhFWBQpbHsz7joyQu+xYT33Qqd2rwpbD1W7b94
# Z7ZbyF4UHLmvhC13ovc5lTdvTn8cxjwE1jHFfu896FF+ca0kdBss3Pl8qu/Cdklo
# YtWL9QPfvn2ODzZ1RluTdsSD7oK+LK43EvG8VsPkrUPDt2aWXpQy+qD2q4lQ+s6g
# 8wiBGtFEp8z3uDECAwEAAaOCAXgwggF0MB8GA1UdIwQYMBaAFBqh+GEZIA/DQXdF
# KI7RNV8GEgRVMB0GA1UdDgQWBBRpdTd7u501Qk6/V9Oa258B0a7e0DAOBgNVHQ8B
# Af8EBAMCBsAwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBA
# BgNVHSAEOTA3MDUGDCsGAQQBsjEBAgEDCDAlMCMGCCsGAQUFBwIBFhdodHRwczov
# L3NlY3RpZ28uY29tL0NQUzBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnNl
# Y3RpZ28uY29tL1NlY3RpZ29SU0FUaW1lU3RhbXBpbmdDQS5jcmwwdAYIKwYBBQUH
# AQEEaDBmMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3Rp
# Z29SU0FUaW1lU3RhbXBpbmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3Nw
# LnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBKA3iQQjPsexqDCTYzmFW7
# nUAGMGtFavGUDhlQ/1slXjvhOcRbuumVkDc3vd/7ZOzlgreVzFdVcEtO9KiH3SKF
# ple7uCEn1KAqMZSKByGeir2nGvUCFctEUJmM7D66A3emggKQwi6Tqb4hNHVjueAt
# D88BN8uNovq4WpquoXqeE5MZVY8JkC7f6ogXFutp1uElvUUIl4DXVCAoT8p7s7Ol
# 0gCwYDRlxOPFw6XkuoWqemnbdaQ+eWiaNotDrjbUYXI8DoViDaBecNtkLwHHwaHH
# JJSjsjxusl6i0Pqo0bglHBbmwNV/aBrEZSk1Ki2IvOqudNaC58CIuOFPePBcysBA
# XMKf1TIcLNo8rDb3BlKao0AwF7ApFpnJqreISffoCyUztT9tr59fClbfErHD7s6R
# d+ggE+lcJMfqRAtK5hOEHE3rDbW4hqAwp4uhn7QszMAWI8mR5UIDS4DO5E3mKgE+
# wF6FoCShF0DV29vnmBCk8eoZG4BU+keJ6JiBqXXADt/QaJR5oaCejra3QmbL2dlr
# L03Y3j4yHiDk7JxNQo2dxzOZgjdE1CYpJkCOeC+57vov8fGP/lC4eN0Ult4cDnCw
# KoVqsWxo6SrkECtuIf3TfJ035CoG1sPx12jjTwd5gQgT/rJkXumxPObQeCOyCSzi
# JmK/O6mXUczHRDKBsq/P3zCCB6IwggWKoAMCAQICExcAAAAIOxvHeeU8zCcAAAAA
# AAgwDQYJKoZIhvcNAQELBQAwMzELMAkGA1UEBhMCVVMxDTALBgNVBAoTBFVQTUMx
# FTATBgNVBAMTDFVQTUMtUm9vdC1DQTAeFw0xNjA1MDkyMjU3NDhaFw0yNjA1MDky
# MzA3NDhaMFcxEzARBgoJkiaJk/IsZAEZFgNuZXQxFjAUBgoJkiaJk/IsZAEZFgZ1
# cG1jaHMxFDASBgoJkiaJk/IsZAEZFgRhY2N0MRIwEAYDVQQDEwlVUE1DLUNBMjAw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQD8cLRMOpJjxu5XNBGPfdSU
# 46rzPrqJzCpTh4RaCnoFZf0/VTcaQPkIJ9tz1cIfSJKyE+B+M8ohq4ItCOE4lffw
# NuK9VeELSJF9xdpSH8+lv2kMTF0qiolRRcgwhV9tjEreV1hJy6ErbBO6fz4h9efN
# XimV5ypKqd+z7zXCsxMu58iqGGtA4w+GDu8ChxNcOibpFr3U+N7OsclhNTqT4AGE
# BAw92TS2AyP7j48x3qZBTxL+onKx1N+4cZCKqHXmuVLWY9hgYcFT21Mks6DHFqaD
# ub3diXpZ3NQF31O5ViNw/IrprOcCsGZiM2YfcmJic5KaPhVNg44+13DrntZnh0P7
# zSc9VPlJJm6TOMEuVoFo212dStXkSr/XCk8uRuDOgzfPei9zA0AD9JXLzqe5wBJQ
# YNvWXzZ10CVDPTBdNVFBFYDicLNqUCjr56nyvASbeG2/nR7phjOU4E7xkteO5mwr
# JopO3soNiGPWqqMvpz1AZwaqEb3KuQFz6wOs0ftDfPZQIpbSwK1G/mzzTc/iGr39
# O4Uf5UFQ5h/qPQ3JGe92yBF1ieU0rfgTgTXm2dBFHci/odUdBWvz4bd9QiWW6MZr
# b7Xg1kUwndur3y0KfE6CjhF14MP4blx6+Cm9v8IKNKbQYtqorlgwW0sowZOIiRYg
# kCrhx0i/ZB8pp7sYSFRaVQIDAQABo4ICiTCCAoUwEAYJKwYBBAGCNxUBBAMCAQAw
# HQYDVR0OBBYEFPgMpPZrzN1/GvenE8LLtMNIgMw6MBkGCSsGAQQBgjcUAgQMHgoA
# UwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQY
# MBaAFBM+w+NjWkYIC76uHypMPnmtW04bMIH9BgNVHR8EgfUwgfIwge+ggeyggemG
# gbhsZGFwOi8vL0NOPVVQTUMtUm9vdC1DQSxDTj1XSU5QS0lOU1BSRDAyLENOPUNE
# UCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25m
# aWd1cmF0aW9uLERDPVVQTUNIUyxEQz1ORVQ/Y2VydGlmaWNhdGVSZXZvY2F0aW9u
# TGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hixodHRw
# Oi8vdXBtY2NybC51cG1jLmNvbS9DRFAvVVBNQy1Sb290LUNBLmNybDCB9wYIKwYB
# BQUHAQEEgeowgecwgaoGCCsGAQUFBzAChoGdbGRhcDovLy9DTj1VUE1DLVJvb3Qt
# Q0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2Vz
# LENOPUNvbmZpZ3VyYXRpb24sREM9VVBNQ0hTLERDPU5FVD9jQUNlcnRpZmljYXRl
# P2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTA4BggrBgEF
# BQcwAoYsaHR0cDovL3VwbWNjcmwudXBtYy5jb20vQ0RQL1VQTUMtUm9vdC1DQS5j
# cnQwDQYJKoZIhvcNAQELBQADggIBAE1Mps2mF2mqJpmy1aYZhtX8Sn21rDR8m50l
# uIgr4S18ETzCKUiMZGWb7FJ/5QtTf1NRPq5hmz5n/Z6pah8dKJzTsI6USJS2eY7P
# R6RRra9cgFHdvfERWymzO+uDyk6UOAv63SBb19QRVsuh1sDzm/tLDF5ocdx0ftC4
# zmYjN72aRSVWUuQuLgTwqakq5NKs5DELbtFZXW8PhLu0wST4m/ao+K5lCjxLcjrc
# DGNR2VetKW6wng/QblYqZbirQpBwbVFBq5+RLb9bmt401u3PDrmQwxE3zOjizbZB
# Pvd7UA3GYvea4B9oIzEBiCnNrKI1vqSRc/EDKdFezytSyRflY8Sb4c5kEGYhkLl0
# OTcgVQyE7t9V/tlDcrjilddGdEs5/OQpB+O4DaOWa7ofTNflz8QO8J2ya0rTNno6
# AdThuz8EcBfb7DuNdlpJxFDHdSzkqSaY2ihpHKzGXl0O4J60DfOtO5eR4XQxvhMw
# Ir7N2ljULmLreqhxYG3Ah3JO5QS1U/U8np1XmlAiLq1GI9qV1BUDR4Edle/QwB0x
# 4PSTBuNJ5a0SXDsEWmWX8acjiFQW2OY8pSDpSQ1nltmg6CNMmQUcy1XdCB63f57J
# jMjnZc33Xah2rcN3TiiYkZ29JmsQL4qjx79hry85t/K3dnSdR5gmR06Zq7JkYy+P
# FU2YhtWdMYIFXzCCBVsCAQEwbjBXMRMwEQYKCZImiZPyLGQBGRYDbmV0MRYwFAYK
# CZImiZPyLGQBGRYGdXBtY2hzMRQwEgYKCZImiZPyLGQBGRYEYWNjdDESMBAGA1UE
# AxMJVVBNQy1DQTIwAhNRAAAHzCAiGCtnq0wIAAAAAAfMMAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBRc6sObHRHpOnqaoSJR61q5RsnJbDANBgkqhkiG9w0BAQEFAASCAQBhV3wgcEsa
# AptHA5V2ktwe3941VzdQhe3iyNXMY2Nep5bC8Fo3NZXM6AGDwAOGLNSoC3O2pZux
# whjS4wVIyp66631DeqoXTop6jPX71mIlmNOoogi+GNrfhdI3wEudfrRoor/GVmNf
# TliQv65fstM6gUqeU0iTEE1SekPsc64s6GQWn6NxL+x4XrLXDHFrXSmUZp4yCpyq
# eyhgJyF9Tok4rmQsDO45CuD8RwHlzPGup09c3p6qWStMPcKjxVymwrKDXxYRcfA3
# PWUcQnczCY8aB6jy+pVIfK02mCck8Wfxgxt6iLyCveh+Mzh+jaUJqjiB+0uHl3oW
# RhSHKPgNvDBboYIDTDCCA0gGCSqGSIb3DQEJBjGCAzkwggM1AgEBMIGSMH0xCzAJ
# BgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcT
# B1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2Vj
# dGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQQIRAIx3oACP9NGwxj2fOkiDjWswDQYJ
# YIZIAWUDBAICBQCgeTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0yMTExMDgxNjA2MjlaMD8GCSqGSIb3DQEJBDEyBDAs2JryT42CIZDj
# tLCLKccfngkeW5Cds/eXRYGEMxIJWR40WIUY9I+994GnGIYwiCQwDQYJKoZIhvcN
# AQEBBQAEggIACDxPBGttzGhhyxoRlSqeg2ratHhberSuoYlgEeMLaRKBVbTtJTn+
# TjfUMfET5jl+rtgm9MgJKqJ5XEA10maCM7pMUamQUk8k+Ss5wVODcBzelucfOiCy
# RnbI3sl8kKrFwOEj6y8HjZDMqEKkX0tR410/s6/KDLBMFLtI62UvVD/6cx5tGslD
# A0D0olpNqAWM/M9RMrJAPzNpOykrz0OHDoare3rQV5rI5hXmafnePyAZKKJ4UkHh
# eyKFD4avQcLb+2djrXQFV/7yRULV4hXoHM3HfXbi9u1r9yNH2OgSEwaBx+Y8Ijvy
# pfxoo0skyxPdBknJCvl/CjDTM5/MaJZEknuP84ASj54lv6Xd7GtGHNmpQOUzTksu
# kMLCwsGE1ivAitbz7fm1i4RaB685hQqHT6PFn7fKahPOXjyx8q3Wt66/2wisYN5u
# i1WbRWkeF3ND8/i8beo0szGrNavCC/FH25JOoOS0vTkgZ80krmcXmx0uA0B8xRim
# DnVl2xruMXZLQbaLxbZiOKLfdlLygiog74BU/o98ArJCHuNVT8VkzJ6NR3bFF1sB
# Ef7ERaEIrOOIxtyxGwsok/NfCFD7wyihRzvcvjylD1KLEBDIHAzwN5wZUT56/yg8
# hNKU1hTVeZZCyeQ+HqT/glYVuyN4rkEYryz7P3jQhBJIttMub6Bikx0=
# SIG # End signature block
