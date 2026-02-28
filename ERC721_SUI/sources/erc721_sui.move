module erc721_sui::ERC721;

use sui::package::{Self, Publisher};
use sui::display;
use sui::event;
use sui::table::{Self, Table};

public struct ERC721Token has key, store{
    id: UID,
    collection_id: u64,
    name: vector<u8>,
    image_url: vector<u8>,
    description: vector<u8>
}

public struct ERC721_Info has key {
    id: UID,
    balances: Table<address, u64>,
    tokenOwners: Table<ID, address>,
    total_supply: u64
}

public struct ERC721Token_Minted has copy, drop{
    token_id: ID,
    token_name: vector<u8>,
}

public struct Only_Owner has key, store { id: UID }

public struct ERC721 has drop {}

fun init(otw: ERC721, ctx: &mut TxContext){
    let publisher: Publisher = package::claim(otw, ctx);

    let keys = vector[
        b"name".to_string(),
        b"image_url".to_string(),
        b"description".to_string(),
        b"creator".to_string(),
    ];

    let values = vector[
        b"{name}".to_string(),
        b"https://purple-funny-halibut-437.mypinata.cloud/ipfs/{image_url}".to_string(),
        b"{description}".to_string(),
        b"ERC721_SUI package".to_string(),
    ];

    let mut display = display::new_with_fields<ERC721Token>(&publisher, keys, values, ctx);

    display.update_version();

    let balances = table::new<address, u64>(ctx);
    let tokenOwners = table::new<ID, address>(ctx);

    let token_info = ERC721_Info {
        id: object::new(ctx),
        balances: balances,
        tokenOwners: tokenOwners,
        total_supply: 0
    };

    let cap = Only_Owner { id: object::new(ctx) };

    transfer::public_transfer(cap, ctx.sender());
    transfer::share_object(token_info);
    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
}

public fun update_token_info(
    _: &Only_Owner, 
    token: &ERC721Token,
    token_onwer: address,
    token_info: &mut ERC721_Info,
    balances: &mut Table<address, u64>,
    tokenOwners: &mut Table<ID, address>,
    // ctx: &mut TxContext
){
    let token_count = token_info.total_supply + 1;

    balances.add(token_onwer, token_count);
    tokenOwners.add(object::id(token), token_onwer);
    
    token_info.total_supply = token_count;

}

public fun mint_token(
    name: vector<u8>,
    collection_id: u64,
    image_url: vector<u8>,
    description: vector<u8>,
    ctx: &mut TxContext
): ERC721Token {
    let token =  ERC721Token {
        id: object::new(ctx),
        collection_id,
        name,
        image_url,
        description
    };

    event::emit(ERC721Token_Minted {
        token_id: object::id(&token),
        token_name: token.name,
    });

    token
}




//PS: After basic implementation, turn this into something another dev can use as library for deploying their own NFT collection on SUI.