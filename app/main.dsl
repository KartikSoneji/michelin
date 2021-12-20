context{
    input phone: string;
    input item: string;

    currentList: string = "ingredients";
    listLength: number = 0;
    currentIndex: number = 0;
    oldIndex: number = -1;
}

external function getListLength(list: string): number;
external function getListItem(list: string, index: number): string;

start node root{
    do{
        #connectSafe($phone);
        
        #sayText("Hi, thank you for choosing to cook with Michelin. What would you like to cook today?");
        wait *;
    }
}

digression start_ingredients{
    conditions{
        on #messageHasIntent("pizza");
    }
    do{
        set $currentList = "ingredients";
        #sayText("Here are the ingredients:");
        
        goto set_list;
    }
    transitions{
        set_list: goto set_list;
    }
}

node set_list{
    do{
        set $listLength = external getListLength($currentList);
        set $currentIndex = 0;
        set $oldIndex = -1;
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

node read_item{
    do{
        var instructions = external getListItem($currentList, $currentIndex);
        #sayText(instructions);
        wait *;
    }
}

digression next{
    conditions{
        on #messageHasIntent("next_step");
    }
    do{
        if($oldIndex == -1){
            if($currentIndex + 1 < external getListLength($currentList)){
                set $currentIndex += 1;
            }
            else{
                if($currentList == "ingredients"){
                    #sayText("Here are the steps:");
                    set $currentList = "steps";
                    goto set_list;
                }
                else if($currentList == "steps"){
                    #sayText("And that's it! Your dish is ready.");
                }
                goto hangup;
            }
        }
        else{
            set $currentIndex = $oldIndex;
            set $oldIndex = -1;
        }
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
        hangup: goto hangup;
        set_list: goto set_list;
    }
}

digression previous{
    conditions{
        on #messageHasIntent("previous_step");
    }
    do{
        if($currentIndex > 0){
            set $currentIndex -= 1;
        }
        else{
            #sayText("You have reached the start, nothing to see here");
        }
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

digression first{
    conditions{
        on #messageHasIntent("first_step");
    }
    do{
        set $currentIndex = 0;
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

digression last{
    conditions{
        on #messageHasIntent("last_step");
    }
    do{
        set $currentIndex = $listLength - 1;
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

digression repeat{
    conditions{
        on #messageHasIntent("repeat_step");
    }
    do{
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

digression goto_step{
    conditions{
        on #messageHasIntent("goto_step");
    }
    do{
        var newIndex = #messageGetData("numberword")[0]?.value;
        if(newIndex is not null){
            set $oldIndex = $currentIndex;
            set $currentIndex = #parseInt(newIndex);
        }
        else{
            #sayText("Sorry, I didn't quite get that, can you please try again");
            return;
        }
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

node hangup{
    do{
        #sayText("Thank you for cooking with Michelin. We hope you enjoy your meal.");
        #disconnect();
        exit;
    }
}
