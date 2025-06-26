import requests
import json

def search_openfda(drug_name, limit=100):
    """
    Search openFDA API for information about a specific drug.
    
    Parameters:
    - drug_name (str): Name of the drug to search for
    - limit (int): Maximum number of results to return (default 100)
    
    Returns:
    - Dictionary containing results from openFDA API
    """
    
    # Base URL for openFDA API
    base_url = "https://api.fda.gov/drug/"
    
    try:
        # Search in the event database (adverse events)
        event_url = f"{base_url}event.json?search=patient.drug.medicinalproduct:{drug_name}&limit={limit}"
        event_response = requests.get(event_url)
        event_data = event_response.json()
        
        # Search in the label database (drug labeling)
        label_url = f"{base_url}label.json?search=openfda.brand_name:{drug_name}+OR+openfda.generic_name:{drug_name}&limit={limit}"
        label_response = requests.get(label_url)
        label_data = label_response.json()
        
        return {
            'adverse_events': event_data,
            'labeling': label_data
        }
        
    except requests.exceptions.RequestException as e:
        print(f"Error making API request: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing API response: {e}")
        return None

def main():
    # Get user input for drug name
    # drug_name = input("Enter the name of the medicine you want to search for: ")
    drug_name = "calendula"
    # Make the API call
    results = search_openfda(drug_name)
    
    if results:
        # Print basic information
        print(f"\nResults for '{drug_name}':")
        
        # Adverse events summary
        if 'results' in results['adverse_events']:
            event_count = len(results['adverse_events']['results'])
            print(f"\nFound {event_count} adverse event reports")
            
            # Uncomment to see detailed adverse event data
            # print(json.dumps(results['adverse_events'], indent=2))
        
        # Labeling information
        if 'results' in results['labeling']:
            label_count = len(results['labeling']['results'])
            print(f"Found {label_count} labeling documents")
            
            # Print first label if available
            if label_count > 0:
                first_label = results['labeling']['results'][0]
                print("\nSample label information:")
                print(f"Brand Name: {first_label.get('openfda', {}).get('brand_name', ['N/A'])[0]}")
                print(f"Generic Name: {first_label.get('openfda', {}).get('generic_name', ['N/A'])[0]}")
                print(f"Manufacturer: {first_label.get('openfda', {}).get('manufacturer_name', ['N/A'])[0]}")
                print(f"Purpose: {first_label.get('purpose', ['N/A'])[0]}")
                
                # Uncomment to see full label data
                # print(json.dumps(results['labeling'], indent=2))
        
        # Option to save results to a file
        save_file = input("\nWould you like to save the results to a JSON file? (y/n): ").lower()
        if save_file == 'y':
            filename = f"{drug_name.lower().replace(' ', '_')}_openfda_results.json"
            with open(filename, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"Results saved to {filename}")
    else:
        print("No results found or error occurred.")

if __name__ == "__main__":
    main()