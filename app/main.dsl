context
{
    input phone: string;

    currentList: string = "ingredients";

    listLength: number = 0;
    currentIndex: number = 0;
    oldIndex: number = -1;
}

external function getListLength(list: string): number;
external function getListItem(list: string, index: number): string;

start node root {
    do {
        #connectSafe($phone);

        #sayText("Hi, thank you for choosing to cook with Michelin.");
        #sayText("What would you like to cook today?");

        #waitForSpeech(5000);

        goto next;
    }
    transitions {
        next: goto start_ingredients;
    }
}

node start_ingredients{
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
    }
}

digression next{
    conditions{
        on #messageHasIntent("next_step");
    }
    do{
        if($oldIndex == -1){
            if($currentIndex < $listLength){
                set $currentIndex += 1;
            }
            else{
                if($currentList == "ingredients"){
                    #sayText("Here are the steps:");
                }
                else if($currentList == "steps"){
                    #sayText("And that's it! Your dish is ready.");
                }
                goto hangup;
            }
        }
        else{
            set $currentIndex = $oldIndex;
        }
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
        hangup: goto hangup;
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
            #sayText("Sorry, I didn't get that, can you please try again?");
            set $currentIndex =-1;
        }
        goto read_item;
    }
    transitions{
        read_item: goto read_item;
    }
}

node hangup{
    do
    {
        #sayText("Thank you for cooking with Michelin. We hope you enjoy your meal.");
        #disconnect();
        exit;
    }
}
