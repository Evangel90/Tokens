module erc721_sui::erc721;

use sui::package::{Self, Publisher};
use sui::display;
use sui::event;

public struct ERC721Token has key, store{
    id: UID,
    name: vector<u8>,
    image_url: vector<u8>,
    description: vector<u8>
}

public struct ERC721Token_Minted has copy, drop{
    token_id: ID,
    token_name: vector<u8>,
}

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

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
}

public fun mint_token(
    name: vector<u8>,
    image_url: vector<u8>,
    description: vector<u8>,
    ctx: &mut TxContext
): ERC721Token {
    let token =  ERC721Token {
        id: object::new(ctx),
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



