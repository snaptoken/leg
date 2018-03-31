require "test_helper"

STEP_1 = <<~END
  int main(void) {}
END

STEP_2 = <<~END
  int main(void) {
    return 0;
  }
END

STEP_3 = <<~END
  int main(void) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_4 = <<~END
  #include <stdio.h>

  int main(void) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_2B = <<~END
  int main(int argc, char *argv[]) {
    return 0;
  }
END

STEP_3B = <<~END
  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_4B = <<~END
  #include <stdio.h>

  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_4C = <<~END
  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }

  // the end
END

STEP_5C = <<~END
  #include <stdio.h>

  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }

  // the end
END

LITDIFF = <<~END
~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
new file mode 100644
--- /dev/null
+++ b/hello.c
@@ -0,0 +1,1 @@
+int main(void) {}

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -1,1 +1,3 @@
-int main(void) {}
+int main(int argc, char *argv[]) {
+  return 0;
+}

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -1,3 +1,5 @@
|int main(int argc, char *argv[]) {
+  printf("Hello, world!\\n");
+
|  return 0;
|}

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -3,3 +3,5 @@
|
|  return 0;
|}
+
+// the end

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -1,3 +1,5 @@
+#include <stdio.h>
+
|int main(int argc, char *argv[]) {
|  printf("Hello, world!\\n");
|

END

describe "leg workflow" do
  it "must allow creating and modifying a tutorial" do
    Dir.mktmpdir do |dir|
      FileUtils.cd(dir)

      #Leg::CLI.new.run(["init"])
      FileUtils.mkdir_p(".leg/repo")
      FileUtils.mkdir_p("step")
      FileUtils.mkdir_p("doc")
      File.write("leg.yml", "---")
      FileUtils.cd(".leg/repo") { `git init` }

      File.write("step/hello.c", STEP_1)
      Leg::CLI.new.run(["commit"])

      File.write("step/hello.c", STEP_2)
      Leg::CLI.new.run(["commit"])

      File.write("step/hello.c", STEP_3)
      Leg::CLI.new.run(["commit"])

      File.write("step/hello.c", STEP_4)
      Leg::CLI.new.run(["commit"])

      Leg::CLI.new.run(["1"])
      File.read("step/hello.c").must_equal(STEP_1)

      Leg::CLI.new.run(["2"])
      File.read("step/hello.c").must_equal(STEP_2)

      Leg::CLI.new.run(["3"])
      File.read("step/hello.c").must_equal(STEP_3)

      Leg::CLI.new.run(["reset"])
      File.read("step/hello.c").must_equal(STEP_4)

      Leg::CLI.new.run(["2"])
      File.read("step/hello.c").must_equal(STEP_2)

      File.write("step/hello.c", STEP_2B)
      Leg::CLI.new.run(["amend"])
      File.read("step/hello.c").must_match(/^<<<<<<< HEAD$/)

      File.write("step/hello.c", STEP_3B)
      Leg::CLI.new.run(["resolve"])
      File.read("step/hello.c").must_match(/^<<<<<<< HEAD$/)

      File.write("step/hello.c", STEP_4B)
      Leg::CLI.new.run(["resolve"])
      File.read("step/hello.c").wont_match(/^<<<<<<< HEAD$/)

      Leg::CLI.new.run(["1"])
      File.read("step/hello.c").must_equal(STEP_1)

      Leg::CLI.new.run(["2"])
      File.read("step/hello.c").must_equal(STEP_2B)

      Leg::CLI.new.run(["3"])
      File.read("step/hello.c").must_equal(STEP_3B)

      Leg::CLI.new.run(["reset"])
      File.read("step/hello.c").must_equal(STEP_4B)

      Leg::CLI.new.run(["3"])
      File.read("step/hello.c").must_equal(STEP_3B)

      File.write("step/hello.c", STEP_4C)
      Leg::CLI.new.run(["commit"])
      File.read("step/hello.c").must_equal(STEP_5C)

      File.read("doc/tutorial.litdiff").must_equal(LITDIFF)
    end
  end
end
