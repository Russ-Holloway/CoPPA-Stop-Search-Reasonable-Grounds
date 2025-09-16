# UK Police Force Codes Reference

This reference guide provides standardized force codes for CoPA Stop & Search deployments.

## 🏛️ England & Wales Police Forces

| Force Name | Code | Full Name | Region |
|------------|------|-----------|--------|
| **avon-somerset** | `avon-somerset` | Avon and Somerset Constabulary | South West |
| **bedfordshire** | `bedfordshire` | Bedfordshire Police | East |
| **btp** | `btp` | British Transport Police | National |
| **cambridgeshire** | `cambridgeshire` | Cambridgeshire Constabulary | East |
| **cheshire** | `cheshire` | Cheshire Constabulary | North West |
| **city-london** | `city-london` | City of London Police | London |
| **cleveland** | `cleveland` | Cleveland Police | North East |
| **cumbria** | `cumbria` | Cumbria Constabulary | North West |
| **derbyshire** | `derbyshire` | Derbyshire Constabulary | East Midlands |
| **devon-cornwall** | `devon-cornwall` | Devon and Cornwall Police | South West |
| **dorset** | `dorset` | Dorset Police | South West |
| **durham** | `durham` | Durham Constabulary | North East |
| **essex** | `essex` | Essex Police | East |
| **gloucestershire** | `gloucestershire` | Gloucestershire Constabulary | South West |
| **gmp** | `gmp` | Greater Manchester Police | North West |
| **hampshire** | `hampshire` | Hampshire Constabulary | South East |
| **hertfordshire** | `hertfordshire` | Hertfordshire Constabulary | East |
| **humberside** | `humberside` | Humberside Police | Yorkshire |
| **kent** | `kent` | Kent Police | South East |
| **lancashire** | `lancashire` | Lancashire Constabulary | North West |
| **leicestershire** | `leicestershire` | Leicestershire Police | East Midlands |
| **lincolnshire** | `lincolnshire` | Lincolnshire Police | East Midlands |
| **merseyside** | `merseyside` | Merseyside Police | North West |
| **met** | `met` | Metropolitan Police Service | London |
| **norfolk** | `norfolk` | Norfolk Constabulary | East |
| **northamptonshire** | `northamptonshire` | Northamptonshire Police | East Midlands |
| **northumbria** | `northumbria` | Northumbria Police | North East |
| **north-yorkshire** | `north-yorkshire` | North Yorkshire Police | Yorkshire |
| **nottinghamshire** | `nottinghamshire` | Nottinghamshire Police | East Midlands |
| **south-yorkshire** | `south-yorkshire` | South Yorkshire Police | Yorkshire |
| **staffordshire** | `staffordshire` | Staffordshire Police | West Midlands |
| **suffolk** | `suffolk` | Suffolk Constabulary | East |
| **surrey** | `surrey` | Surrey Police | South East |
| **sussex** | `sussex` | Sussex Police | South East |
| **thames-valley** | `thames-valley` | Thames Valley Police | South East |
| **warwickshire** | `warwickshire` | Warwickshire Police | West Midlands |
| **west-mercia** | `west-mercia` | West Mercia Police | West Midlands |
| **west-yorkshire** | `west-yorkshire` | West Yorkshire Police | Yorkshire |
| **wiltshire** | `wiltshire` | Wiltshire Police | South West |
| **wmp** | `wmp` | West Midlands Police | West Midlands |

## 🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland Police Forces

| Force Name | Code | Full Name | Region |
|------------|------|-----------|--------|
| **police-scotland** | `police-scotland` | Police Scotland | Scotland |

## 🏴󠁧󠁢󠁷󠁬󠁳󠁿 Wales Police Forces

| Force Name | Code | Full Name | Region |
|------------|------|-----------|--------|
| **dyfed-powys** | `dyfed-powys` | Dyfed-Powys Police | Wales |
| **gwent** | `gwent` | Gwent Police | Wales |
| **north-wales** | `north-wales` | North Wales Police | Wales |
| **south-wales** | `south-wales` | South Wales Police | Wales |

## 🇮🇪 Northern Ireland Police Forces

| Force Name | Code | Full Name | Region |
|------------|------|-----------|--------|
| **psni** | `psni` | Police Service of Northern Ireland | Northern Ireland |

## 🛡️ Specialist Forces

| Force Name | Code | Full Name | Type |
|------------|------|-----------|------|
| **btp** | `btp` | British Transport Police | Transport |
| **cmp** | `cmp` | Civil Nuclear Constabulary | Nuclear |
| **mod-police** | `mod-police` | Ministry of Defence Police | Defence |

## 📋 Naming Convention

### Resource Naming Pattern:
```
Resource Group: rg-{force-code}-uks-p-copa-stop-search
Web App: app-{force-code}-uks-p-copa-stop-search
URL: https://app-{force-code}-uks-p-copa-stop-search.azurewebsites.net
```

### Examples:
```
Metropolitan Police:
- Code: met
- Resource Group: rg-met-uks-p-copa-stop-search  
- URL: https://app-met-uks-p-copa-stop-search.azurewebsites.net

Greater Manchester Police:
- Code: gmp
- Resource Group: rg-gmp-uks-p-copa-stop-search
- URL: https://app-gmp-uks-p-copa-stop-search.azurewebsites.net

Thames Valley Police:
- Code: thames-valley
- Resource Group: rg-thames-valley-uks-p-copa-stop-search
- URL: https://app-thames-valley-uks-p-copa-stop-search.azurewebsites.net
```

## 🎯 Usage Notes

1. **Force codes are lowercase** with hyphens for spaces
2. **Codes must be unique** across all UK forces
3. **Maximum length is 20 characters** for Azure resource naming limits
4. **Use official force names** as the basis for codes
5. **Regional forces** use full names (devon-cornwall, thames-valley)

## 🔄 Adding New Forces

When adding a new force:
1. Check this reference for the correct code
2. Ensure code follows naming convention
3. Verify code doesn't conflict with existing deployments
4. Update this reference if adding new codes

---

**Need to add a force not listed here?** Contact BTP CoPA team for code assignment and standardization.