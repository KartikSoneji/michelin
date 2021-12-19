context
{
    input phone: string;
    stepIndex: number = 0;
    oldIndex: number = -1;
    totalSteps: number = 0;
}

external function getIngredients(): string;
external function getStepCount(): number;
external function getInstructionsForStep(stepNumber: number): string;

start node root {
    do {
        #connectSafe($phone);
        $totalSteps = external getStepCount();
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
            if($stepIndex < $totalSteps){
                set $stepIndex += 1;
            }
            else{
                goto hangup;
            }
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
        #sayText("Thank you for cooking with Michelin. We hope you enjoy your meal.");
        #disconnect();
        exit;
    }
}
