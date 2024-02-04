package main

import (
  "fmt"
  "log"
  "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Asset describes basic details of what makes up a simple asset
type Bank struct {
    Id             string `json:"id"`
	Name 		   string `json:"name"`
    HQ             string `json:"hq"`
    FoundingYear   int    `json:"foundingYear"`
    PIB            string `json:"pib"`
    Clients 	   []string  `json:"clients"`
}

type Client struct {
	Id	string	`json:"id"`
	FirstName string `json:"firstName"`
	LastName string `json:"lastName"`
	Email string `json:"email"`
	Accounts []string `json:"accounts"`
}

type Account struct {
	Id string `json:"id"`
	Ballance float64 `json:"ballance"`
	Currency string `json:"currency"`
	//Cards map[string]Card `json:"cards"`
}

// SmartContract provides functions for managing an Asset
type SmartContract struct {
	contractapi.Contract
}

// InitLedger adds a base set of assets to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {

	banks := []Bank {
		{Id:"bank1", Name:"Cacanska banka", HQ:"Cacak", FoundingYear:1408, PIB:"1408", Clients:{}},
		{Id:"bank2", Name:"Kosovska banka", HQ:"Ljubic", FoundingYear:1389, PIB:"1389", Clients:{}},
		{Id:"bank3", Name:"Banka svetog trojstva", HQ:"Cacak", FoundingYear:333, PIB:"3333", Clients:{}},
	}

	clients := []Client {
		{Id:"client1", FirstName:"Skabo", LastName:"Maestro", Email:"skabo@gmail.com", Accounts:{}},
		{Id:"client2", FirstName:"Raca", LastName:"Braca", Email:"racabraca@gmail.com", Accounts:{}},
		{Id:"client3", FirstName:"Milos", LastName:"Obilic", Email:"losmiKralj1389@gmail.com", Accounts:{}},
		{Id:"client4", FirstName:"Bosko", LastName:"Jugovic", Email:"jugovicaMother@gmail.com", Accounts:{}},
	}

	accounts := []Account {
		{Id:"account1Eur", Ballance:1000.0, Currency:"EUR"},
		{Id:"account2Eur", Ballance:1000.0, Currency:"EUR"},
		{Id:"account3Eur", Ballance:1000.0, Currency:"EUR"},
		{Id:"account4Eur", Ballance:1000.0, Currency:"EUR"},
		{Id:"account1Rsd", Ballance:1000.0, Currency:"RSD"},
		{Id:"account2Rsd", Ballance:1000.0, Currency:"RSD"},
		{Id:"account3Rsd", Ballance:1000.0, Currency:"RSD"},
		{Id:"account4Rsd", Ballance:1000.0, Currency:"RSD"},
	}

	clients[0].Accounts = append(clients[0].Accounts, "account1Eur", "account1Rsd")
	clients[1].Accounts = append(clients[1].Accounts, "account2Eur", "account2Rsd")
	clients[2].Accounts = append(clients[2].Accounts, "account3Eur", "account3Rsd")
	clients[3].Accounts = append(clients[3].Accounts, "account4Eur", "account4Rsd")

	banks[0].Clients = append(banks[0].Clients, "client1", "client2")
	banks[1].Clients = append(banks[1].Clients, "client3", "client4")

	for _, bank := range banks {
		bankJSON, err := json.Marshal(bank)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(bank.Id, bankJSON)
		if err != nil {
			return fmt.Errorf("failed to put bank to world state. %v", err)
		}
  	}

	for _, client := range clients {
		clientJSON, err := json.Marshal(client)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(client.Id, clientJSON)
		if err != nil {
			return fmt.Errorf("failed to put client to world state. %v", err)
		}
  	}

	for _, account := range accounts {
		accountJSON, err := json.Marshal(account)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(account.Id, accountJSON)
		if err != nil {
			return fmt.Errorf("failed to put account to world state. %v", err)
		}
  	}


  return nil
}

// CreateAsset issues a new asset to the world state with given details.
func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, id string, color string, size int, owner string, appraisedValue int) error {
    exists, err := s.AssetExists(ctx, id)
    if err != nil {
      return err
    }
    if exists {
      return fmt.Errorf("the asset %s already exists", id)
    }

    asset := Asset{
      ID:             id,
      Color:          color,
      Size:           size,
      Owner:          owner,
      AppraisedValue: appraisedValue,
    }
    assetJSON, err := json.Marshal(asset)
    if err != nil {
      return err
    }

    return ctx.GetStub().PutState(id, assetJSON)
  }

// ReadAsset returns the asset stored in the world state with given id.
func (s *SmartContract) ReadAsset(ctx contractapi.TransactionContextInterface, id string) (*Asset, error) {
    assetJSON, err := ctx.GetStub().GetState(id)
    if err != nil {
      return nil, fmt.Errorf("failed to read from world state: %v", err)
    }
    if assetJSON == nil {
      return nil, fmt.Errorf("the asset %s does not exist", id)
    }

    var asset Asset
    err = json.Unmarshal(assetJSON, &asset)
    if err != nil {
      return nil, err
    }

    return &asset, nil
  }