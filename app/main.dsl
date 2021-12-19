context
{
    input phone: string;
    stepIndex: number = 0;
    oldIndex: number = -1;
}

external function getInstructionsForStep(stepNumber: number): string;
external function getIngredients(): string;

start node root {
    do {
        #connectSafe($phone);
        goto next;
    }
    transitions {
        next: goto read_ingredients;
    }
}

node read_ingredients{
    do{
        var ingredients = external getIngredients();
        #sayText(ingredients);
        goto home;
    }
    transitions{
        home: goto home;
    }
}

node home{
    do{
        var instructions = external getInstructionsForStep($stepIndex);
        #sayText(instructions);
    }
}

digression next{
    conditions{
        on #messageHasIntent("next_step");
    }
    do{
        if($oldIndex == -1){
            set $stepIndex += 1;
        }
        else{
            set $stepIndex = $oldIndex;
        }
        goto home;
    }
    transitions{
        home: goto home;
    }
}

digression repeat{
    conditions{
        on #messageHasIntent("repeat_step");
    }
    do{
        goto home;
    }
    transitions{
        home: goto home;
    }
}

digression goto_step{
    conditions{
        on #messageHasIntent("goto_step");
    }
    do{
        var newIndex = #messageGetData("numberword")[0]?.value;
        if(newIndex is not null){
            set $oldIndex = $stepIndex;
            set $stepIndex = #parseInt(newIndex);
        }
        else{
            #sayText("Sorry, I didn't get that, can you please try again?");
            set $stepIndex =-1;
        }
        goto home;
    }
    transitions{
        home: goto home;
    }
}

digression hangup
{
    conditions
    {
        on true tags: onclosed;
    }
    do
    {
        #disconnect();
        exit;
    }
    transitions
    {
    }
}
