from pprint import pprint

from src.predict import predict_risk


test_project = {
    "Project_Type": "Software",
    "Team_Size": 8,
    "Project_Budget_USD": 50000,
    "Estimated_Timeline_Months": 8,
    "Complexity_Score": 6.5,
    "Stakeholder_Count": 7,
    "Methodology_Used": "Agile",
    "Team_Experience_Level": "Experienced",
    "Past_Similar_Projects": 4,
    "External_Dependencies_Count": 3,
    "Change_Request_Frequency": 2.0,
    "Project_Phase": "Execution",
    "Requirement_Stability": "Stable",
    "Team_Turnover_Rate": 0.08,
    "Vendor_Reliability_Score": 0.8,
    "Historical_Risk_Incidents": 2,
    "Communication_Frequency": 4.0,
    "Regulatory_Compliance_Level": "High",
    "Technology_Familiarity": "High",
    "Geographical_Distribution": 2,
    "Stakeholder_Engagement_Level": "High",
    "Schedule_Pressure": 0.4,
    "Budget_Utilization_Rate": 0.55,
    "Executive_Sponsorship": "High",
    "Funding_Source": "Internal",
    "Market_Volatility": 0.3,
    "Integration_Complexity": 0.4,
    "Resource_Availability": 0.8,
    "Priority_Level": "High",
    "Organizational_Change_Frequency": 0.2,
    "Cross_Functional_Dependencies": 3,
    "Previous_Delivery_Success_Rate": 0.85,
    "Technical_Debt_Level": 0.25,
    "Project_Manager_Experience": "Experienced",
    "Org_Process_Maturity": "High",
    "Data_Security_Requirements": "High",
    "Key_Stakeholder_Availability": "High",
    "Tech_Environment_Stability": "Stable",
    "Contract_Type": "Fixed Price",
    "Resource_Contention_Level": "Low",
    "Industry_Volatility": "Low",
    "Client_Experience_Level": "Experienced",
    "Change_Control_Maturity": "High",
    "Risk_Management_Maturity": "High",
    "Team_Colocation": "Distributed",
    "Documentation_Quality": "High",
    "Project_Start_Month": 9,
    "Current_Phase_Duration_Months": 2,
    "Seasonal_Risk_Factor": 0.2,
}


if __name__ == "__main__":
    print("=" * 70)
    print("SCALEFLOW - RISK MODEL PREDICTION TEST")
    print("=" * 70)

    result = predict_risk(test_project)

    print("\n=== PREDICTION RESULT ===")
    pprint(result)

    print("\n=== SUMMARY ===")
    print(f"Risk Score: {result['risk_score']}/100")
    print(f"Risk Level: {result['risk_level']}")
    print(f"Confidence: {result['confidence']:.2%}")