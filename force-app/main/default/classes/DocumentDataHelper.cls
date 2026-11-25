/**
 * Shared data for customer-facing documents (Digio templates) and emails.
 *
 * - Company name / short name / address and the payment bank account are
 *   resolved per Project (Project__c.Company__r + Project__c bank fields),
 *   so no document hard-codes a single company or bank account.
 * - Applicant names: the primary applicant is the Opportunity Account; the
 *   co-applicants are Applicant__c records (deduplicated by Account and never
 *   repeating the primary applicant).
 * - Amounts are formatted in the Indian numbering system (1,35,67,543).
 */
public without sharing class DocumentDataHelper {

    public class CompanyDetails {
        public String projectName       = '';
        public String companyName       = '';
        public String companyShortName  = '';
        public String companyAddress    = '';
        public String companyEmail      = '';
        public String bankAccountName   = '';
        public String bankName          = '';
        public String bankBranch        = '';
        public String bankAccountNumber = '';
        public String bankIfscCode      = '';
        public String bankAccountType   = '';
    }

    public class ApplicantNames {
        public String primaryName              = '';
        public String coApplicant1Name         = '';
        public String coApplicant2Name         = '';
        public String allCoApplicantNames      = '';
        /** "Primary & 1st Co-applicant" – used wherever the customer is addressed. */
        public String primaryWithCoApplicant   = '';
        public List<Account> coApplicantAccounts = new List<Account>();
    }

    public static CompanyDetails getCompanyDetailsForOpportunity(Id oppId) {
        if (oppId == null) return new CompanyDetails();
        List<Opportunity> opps = [SELECT Project__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
        return opps.isEmpty() ? new CompanyDetails() : getCompanyDetails(opps[0].Project__c);
    }

    public static CompanyDetails getCompanyDetails(Id projectId) {
        CompanyDetails details = new CompanyDetails();
        if (projectId == null) return details;

        List<Project__c> projects = [
            SELECT Name, Company_Name__c, Account_Name__c, Bank_Name__c, Branch__c, Account_Number__c,
                   IFSC_Code__c, Type_of_Account__c,
                   Company__r.Name, Company__r.Short_Name__c, Company__r.Address__c, Company__r.Email__c
            FROM Project__c WHERE Id = :projectId LIMIT 1
        ];
        if (projects.isEmpty()) return details;
        Project__c p = projects[0];

        details.projectName       = nz(p.Name);
        details.companyName       = firstNonBlank(p.Company__r?.Name, p.Company_Name__c);
        details.companyShortName  = nz(p.Company__r?.Short_Name__c);
        details.companyAddress    = nz(p.Company__r?.Address__c);
        details.companyEmail      = nz(p.Company__r?.Email__c);
        details.bankAccountName   = firstNonBlank(p.Account_Name__c, details.companyName);
        details.bankName          = nz(p.Bank_Name__c);
        details.bankBranch        = nz(p.Branch__c);
        details.bankAccountNumber = nz(p.Account_Number__c);
        details.bankIfscCode      = nz(p.IFSC_Code__c);
        details.bankAccountType   = nz(p.Type_of_Account__c);
        return details;
    }

    public static ApplicantNames getApplicantNames(Id oppId) {
        return getApplicantNames(oppId, false);
    }

    /**
     * @param withSalutation prefix names with the Account salutation ("Mr. Ravi Kumar")
     */
    public static ApplicantNames getApplicantNames(Id oppId, Boolean withSalutation) {
        ApplicantNames names = new ApplicantNames();
        if (oppId == null) return names;

        List<Opportunity> opps = [
            SELECT AccountId, Account.Name, Account.Salutation__c
            FROM Opportunity WHERE Id = :oppId LIMIT 1
        ];
        if (opps.isEmpty()) return names;
        Opportunity opp = opps[0];
        if (opp.AccountId != null) {
            names.primaryName = displayName(opp.Account, withSalutation);
        }

        // Skip the primary applicant and repeated co-applicants, whether the repeat is the same Account
        // or a second Account created with the same name.
        Set<Id> seenAccounts = new Set<Id>();
        Set<String> seenNames = new Set<String>();
        if (opp.AccountId != null) {
            seenAccounts.add(opp.AccountId);
            seenNames.add(nameKey(opp.Account.Name));
        }
        List<String> coNames = new List<String>();
        for (Applicant__c app : [
            SELECT Account__c, Account__r.Id, Account__r.Name, Account__r.Salutation__c
            FROM Applicant__c
            WHERE Opportunity__c = :oppId AND Account__c != null
            ORDER BY CreatedDate ASC
        ]) {
            String key = nameKey(app.Account__r.Name);
            if (seenAccounts.contains(app.Account__c) || (String.isNotBlank(key) && seenNames.contains(key))) continue;
            seenAccounts.add(app.Account__c);
            seenNames.add(key);
            names.coApplicantAccounts.add(app.Account__r);
            coNames.add(displayName(app.Account__r, withSalutation));
        }

        names.coApplicant1Name    = coNames.size() > 0 ? coNames[0] : '';
        names.coApplicant2Name    = coNames.size() > 1 ? coNames[1] : '';
        names.allCoApplicantNames = String.join(coNames, ', ');
        names.primaryWithCoApplicant = String.isBlank(names.coApplicant1Name)
            ? names.primaryName
            : names.primaryName + ' & ' + names.coApplicant1Name;
        return names;
    }

    /** 13567543.5 -> "1,35,67,543.50"; 12345676 -> "1,23,45,676". */
    public static String formatIndianAmount(Decimal amount) {
        if (amount == null) return '0';
        Decimal rounded = amount.setScale(2, RoundingMode.HALF_UP);
        Boolean negative = rounded < 0;
        Decimal absValue = rounded.abs();
        Long wholePart = absValue.setScale(0, RoundingMode.DOWN).longValue();
        Decimal fraction = absValue - wholePart;

        String digits = String.valueOf(wholePart);
        String grouped;
        if (digits.length() <= 3) {
            grouped = digits;
        } else {
            String lastThree = digits.substring(digits.length() - 3);
            String rest = digits.substring(0, digits.length() - 3);
            String head = '';
            while (rest.length() > 2) {
                head = ',' + rest.substring(rest.length() - 2) + head;
                rest = rest.substring(0, rest.length() - 2);
            }
            grouped = rest + head + ',' + lastThree;
        }

        String result = grouped;
        if (fraction != 0) {
            String paise = String.valueOf((fraction * 100).setScale(0, RoundingMode.HALF_UP).intValue()).leftPad(2, '0');
            result += '.' + paise;
        }
        return (negative ? '-' : '') + result;
    }

    /** dd/MM/yyyy, or '' for null. */
    public static String formatDate(Date d) {
        if (d == null) return '';
        return DateTime.newInstance(d.year(), d.month(), d.day()).format('dd/MM/yyyy');
    }

    /**
     * The date the customer actually paid, based on the mode of payment
     * (falls back to the receipt date when the instrument date is blank).
     */
    public static Date paymentMadeDate(Receipt__c r) {
        if (r == null) return null;
        Date d;
        switch on (r.Mode_Of_Payment__c == null ? '' : r.Mode_Of_Payment__c) {
            when 'Cheque'       { d = r.Cheque_Date__c; }
            when 'DD'           { d = r.DD_Date__c; }
            when 'JV'           { d = r.JV_Date__c; }
            when 'UPI'          { d = r.Paid_Date__c; }
            when 'TDS'          { d = r.Challan_Date__c; }
            when 'FUNDTRANSFER' { d = r.Fund_Date__c; }
            when else           { d = r.Fund_Transfer_Date__c != null ? r.Fund_Transfer_Date__c : r.Paid_Date__c; }
        }
        return d != null ? d : r.Receipt_Date__c;
    }

    private static String displayName(Account a, Boolean withSalutation) {
        if (a == null) return '';
        // Full_Name__c is a formula that already prefixes the salutation ("Mr Name"),
        // so build from Name to avoid "Mr. Mr Name".
        String nm = nz(a.Name);
        if (withSalutation == true && String.isNotBlank(a.Salutation__c)) {
            nm = a.Salutation__c.removeEnd('.') + '. ' + nm;
        }
        return nm;
    }

    /**
     * The Digio booking form templates have no Aadhaar slot, so the Aadhaar number is printed on the
     * PAN line, to the right of the PAN: "ABCDE1234F          Aadhaar No: 1234 5678 9012".
     * A 12 digit Aadhaar is grouped in fours; anything else is printed as entered.
     */
    public static String panWithAadhaar(String pan, String aadhaar) {
        String panText = nz(pan).trim();
        String digits = nz(aadhaar).replaceAll('[^0-9]', '');
        String aadhaarText = digits.length() == 12
            ? digits.substring(0, 4) + ' ' + digits.substring(4, 8) + ' ' + digits.substring(8, 12)
            : nz(aadhaar).trim();
        if (String.isBlank(aadhaarText)) {
            return panText;
        }
        return (String.isBlank(panText) ? '-' : panText) + AADHAAR_GAP + 'Aadhaar No: ' + aadhaarText;
    }

    private static final String AADHAAR_GAP = '          ';

    private static String nz(String s) { return s == null ? '' : s; }

    private static String nameKey(String name) {
        return nz(name).normalizeSpace().toLowerCase();
    }

    private static String firstNonBlank(String a, String b) {
        return String.isNotBlank(a) ? a : nz(b);
    }
}