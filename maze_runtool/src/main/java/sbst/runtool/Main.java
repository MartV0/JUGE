package sbst.runtool;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

public class Main {
    public static void main(String[] args) throws IOException {
        String strategy = args.length >= 1 ? args[0] : "DFS";
        //String concreteDriven = "false";
        String extraArgs = args.length >= 2 ? args[1] : "";
        MazeTool tool = new MazeTool(strategy, extraArgs);
        RunTool runtool = new RunTool(tool, new InputStreamReader(System.in),
                new OutputStreamWriter(System.out));
        runtool.run();
    }
}
